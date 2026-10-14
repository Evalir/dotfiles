"""Apply published fixture revisions without touching the real home or editor."""
import argparse
import json
import os
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import reconcile_state as state
import sync_cli
from test_reconcile_state import State


class Sync(unittest.TestCase):
    commit = State.commit

    def setUp(self):
        State.setUp(self)
        self.home = self.base / 'home'
        self.home.mkdir()
        self.roots = {'home': self.home, 'config': self.home / '.config', 'state': self.home / '.local/state'}
        self.directory = self.roots['state'] / 'dotfiles'
        self.directory.mkdir(parents=True)
        (self.root / 'config').mkdir()
        self.manifest = {'version': 1, 'profiles': {'headless': ['test']}, 'components': {
            'test': {'links': [['file', 'config', 'test']], 'required': []}}}
        (self.root / 'config/profiles.json').write_text(json.dumps(self.manifest))
        self.second = self.commit()
        state.git(self.root, 'push', 'origin', 'master')
        self.addCleanup(patch.stopall)
        patch.object(sync_cli.editor, 'preflight', return_value={'healthy': True, 'errors': []}).start()
        self.editor = patch.object(sync_cli.editor, 'check', return_value={'healthy': True, 'errors': []}).start()

    def run_command(self, command, **kwargs):
        args = argparse.Namespace(command=command, profile='headless', dry_run=False, revision=None, **{})
        for key, value in kwargs.items():
            setattr(args, key, value)
        return sync_cli.operate(self.root, args, self.roots, self.directory)

    def advance(self, content='new'):
        state.git(self.root, 'checkout', 'master')
        (self.root / 'file').write_text(content)
        revision = self.commit()
        state.git(self.root, 'push', 'origin', 'master')
        state.git(self.root, 'checkout', '--detach', self.second)
        return revision

    def test_adopt_sync_rollback_and_manual_reconcile(self):
        self.assertTrue(self.run_command('adopt')['healthy'])
        revision = self.advance()
        preview = self.run_command('sync', dry_run=True)
        self.assertEqual(preview['target'], revision)
        self.assertEqual(state.git(self.root, 'rev-parse', 'HEAD').stdout.strip(), self.second)
        self.assertEqual(self.run_command('sync')['applied'], revision)
        self.assertEqual((self.home / '.config/test').read_text(), 'new')
        self.assertEqual(self.run_command('rollback')['applied'], self.second)
        state.git(self.root, 'checkout', '--detach', revision)
        self.assertEqual(self.run_command('reconcile')['applied'], revision)
        self.assertTrue(self.run_command('status')['healthy'])

    def test_readiness_failure_and_interruption_keep_applied_revision(self):
        self.run_command('adopt')
        revision = self.advance()
        self.editor.return_value = {'healthy': False, 'errors': ['missing parser']}
        failed = self.run_command('sync')
        self.assertEqual(failed['applied'], self.second)
        self.assertEqual(failed['attempted'], revision)
        self.assertFalse(failed['healthy'])
        self.editor.return_value = {'healthy': True, 'errors': []}
        self.assertEqual(self.run_command('reconcile')['applied'], revision)

    def test_missing_requirement_and_foreign_link_block_before_checkout(self):
        self.run_command('adopt')
        self.manifest['components']['test']['required'] = [{'command': 'absent-dotfiles-fixture-command'}]
        (self.root / 'config/profiles.json').write_text(json.dumps(self.manifest))
        revision = self.commit()
        state.git(self.root, 'push', 'origin', 'master')
        state.git(self.root, 'checkout', '--detach', self.second)
        with self.assertRaisesRegex(ValueError, 'required tools'):
            self.run_command('sync')
        self.assertEqual(state.git(self.root, 'rev-parse', 'HEAD').stdout.strip(), self.second)
        target = self.home / '.config/test'
        target.unlink()
        target.write_text('mine')
        with self.assertRaisesRegex(ValueError, 'Foreign links'):
            self.run_command('reconcile')
        self.assertEqual(target.read_text(), 'mine')

    def test_dirty_checkout_and_running_editor_do_not_write(self):
        self.run_command('adopt')
        (self.root / 'untracked').write_text('mine')
        before = (self.directory / 'state.json').read_bytes()
        with self.assertRaisesRegex(ValueError, 'local changes'):
            self.run_command('sync')
        self.assertEqual((self.directory / 'state.json').read_bytes(), before)
        (self.root / 'untracked').unlink()
        with patch.object(sync_cli.editor, 'preflight', return_value={'healthy': False, 'errors': ['running editor']}):
            with self.assertRaisesRegex(ValueError, 'running editor'):
                self.run_command('reconcile')
        self.assertEqual((self.directory / 'state.json').read_bytes(), before)


if __name__ == '__main__':
    unittest.main()
