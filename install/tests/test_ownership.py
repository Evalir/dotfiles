"""Exercise ownership and interrupted writes in disposable homes."""
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('ownership', ROOT / 'install/ownership.py')
ownership = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ownership)


class Ownership(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name).resolve()
        self.repo = self.home / 'repo'
        self.source = self.repo / 'config'
        self.source.parent.mkdir()
        self.source.write_text('shared')
        self.target = self.home / '.config/test'
        self.state = self.home / '.local/state/dotfiles/links.json'
        self.state.parent.mkdir(parents=True)
        self.roots = [self.home]
        self.report = {'root': str(self.repo), 'profile': 'headless', 'links': [
            {'component': 'fish', 'source': str(self.source), 'target': str(self.target)}]}

    def apply(self, **kwargs):
        ledger = ownership.load(self.state, self.repo)
        return ownership.apply(self.report, self.state, ledger, self.roots, 'revision', **kwargs)

    def test_foreign_conflict_is_preflighted_before_any_links(self):
        self.target.parent.mkdir()
        self.target.write_text('private override')
        first = self.home / '.config/first'
        self.report['links'].insert(0, {**self.report['links'][0], 'target': str(first)})
        with self.assertRaisesRegex(ValueError, '--adopt'):
            self.apply()
        self.assertFalse(first.exists())
        self.assertFalse(self.state.exists())
        self.assertEqual(self.target.read_text(), 'private override')

    def test_adopt_backup_and_repeat_do_not_change_ledger_or_make_more_backups(self):
        self.target.parent.mkdir()
        self.target.write_text('local')
        self.apply(adopt=True)
        ledger = self.state.read_bytes()
        before = self.state.stat().st_mtime_ns
        self.apply()
        self.assertEqual(self.state.read_bytes(), ledger)
        self.assertEqual(self.state.stat().st_mtime_ns, before)
        backups = list(self.target.parent.glob('test.bak.*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'local')
        self.target.unlink()
        self.target.write_text('new user edits')
        with self.assertRaises(ValueError):
            self.apply()
        self.assertEqual(self.target.read_text(), 'new user edits')

    def test_legacy_skill_directory_migration_never_writes_through_checkout(self):
        skills = self.repo / 'agents/skills'
        (skills / 'one').mkdir(parents=True)
        (skills / 'one/SKILL.md').write_text('skill')
        target = self.home / '.agents/skills'
        target.parent.mkdir()
        target.symlink_to(skills)
        self.report['links'] = [{'component': 'skills', 'source': str(skills / 'one'),
                                 'target': str(target / 'one')}]
        with self.assertRaises(ValueError):
            self.apply()
        self.apply(adopt=True)
        self.assertFalse(target.is_symlink())
        self.assertEqual(os.readlink(target / 'one'), str(skills / 'one'))
        self.assertFalse((skills / 'one').is_symlink())
        self.assertEqual((skills / 'one/SKILL.md').read_text(), 'skill')
        foreign = target / 'vendor'
        foreign.mkdir()
        self.apply()
        self.assertTrue(foreign.is_dir())

    def test_foreign_skill_directory_and_other_symlink_parents_are_refused(self):
        outside = self.home / 'foreign'
        outside.mkdir()
        self.target.parent.symlink_to(outside)
        with self.assertRaisesRegex(ValueError, 'symlink parent'):
            self.apply(adopt=True)
        self.assertEqual(list(outside.iterdir()), [])
        self.target.parent.unlink()
        container = self.home / '.agents/skills'
        container.parent.mkdir()
        container.symlink_to(outside)
        self.report['links'][0].update(component='skills', target=str(container / 'one'))
        with self.assertRaisesRegex(ValueError, 'Ambiguous'):
            self.apply(adopt=True)

    def test_prune_only_removes_obsolete_links_still_pointing_to_recorded_source(self):
        self.apply()
        other = self.home / '.config/other'
        self.report['links'].append({**self.report['links'][0], 'target': str(other)})
        self.apply()
        other.unlink()
        other.write_text('user replacement')
        self.report['links'] = []
        self.apply()
        self.assertTrue(self.target.is_symlink())
        self.apply(prune=True)
        self.assertFalse(os.path.lexists(self.target))
        self.assertEqual(other.read_text(), 'user replacement')
        self.assertIn(str(other), json.loads(self.state.read_text())['entries'])

    def test_partial_scope_does_not_prune_other_components(self):
        self.apply()
        self.report.update(profile='bin', links=[])
        self.apply(prune=True)
        self.assertTrue(self.target.is_symlink())

    def test_interrupted_adoption_resumes_without_losing_the_original(self):
        self.target.parent.mkdir()
        self.target.write_text('original')
        with patch.object(Path, 'symlink_to', side_effect=OSError('interrupted')):
            with self.assertRaises(OSError):
                self.apply(adopt=True)
        self.assertFalse(self.target.exists())
        pending = json.loads(self.state.read_text())['entries'][str(self.target)]
        self.assertTrue(pending['pending'])
        self.assertEqual(Path(pending['backup']).read_text(), 'original')
        self.apply()
        self.assertTrue(self.target.is_symlink())
        self.assertEqual(len(list(self.target.parent.glob('test.bak.*'))), 1)
        self.assertNotIn('pending', json.loads(self.state.read_text())['entries'][str(self.target)])

    def test_lock_and_ledger_identity_guards(self):
        with ownership.locked(self.state.parent, self.roots):
            with self.assertRaisesRegex(ValueError, 'running'):
                with ownership.locked(self.state.parent, self.roots):
                    self.fail('second lock acquired')
        self.apply()
        with self.assertRaisesRegex(ValueError, 'another checkout'):
            ownership.load(self.state, self.home / 'different')
        self.state.unlink()
        self.state.symlink_to(self.source)
        with self.assertRaisesRegex(ValueError, 'symlink'):
            ownership.load(self.state, self.repo)


if __name__ == '__main__':
    unittest.main()
