"""Profile contract tests: no live HOME, package managers or remote services."""
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('profile', ROOT / 'install/profile.py')
profile = importlib.util.module_from_spec(spec)
spec.loader.exec_module(profile)


class Profiles(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name)
        self.root = self.base / 'repo'
        self.root.mkdir()
        for name in ('config', 'shell', 'editors', 'agents'):
            shutil.copytree(ROOT / name, self.root / name)
        self.home = self.base / 'home'
        self.roots = {'home': self.home, 'config': self.home / '.config',
                      'state': self.home / '.local/state'}

    def resolve(self, name='headless'):
        return profile.resolve(name, self.root, self.roots)

    def test_headless_has_portable_components_without_gui_or_home_writes(self):
        result = self.resolve()
        self.assertEqual({x['component'] for x in result['links']},
                         {'fish', 'tmux', 'nvim', 'skills', 'launchers'})
        self.assertFalse(self.home.exists())
        self.assertIn('prompt', {x['component'] for x in result['skipped']})
        self.assertNotIn('rex', {x['component'] for x in result['links']})
        self.assertTrue(any(x['component'] == 'rex' for x in self.resolve('desktop')['links']))

    def test_skills_are_individual_and_only_installed_harnesses_are_selected(self):
        (self.home / '.codex').mkdir(parents=True)
        result = self.resolve()
        targets = [Path(x['target']) for x in result['links'] if x['component'] == 'skills']
        self.assertTrue(any('.codex' in x.parts for x in targets))
        self.assertTrue(any('.agents' in x.parts for x in targets))
        self.assertFalse(any('.claude' in x.parts or '.cursor' in x.parts for x in targets))
        self.assertTrue(all(x.name != 'skills' for x in targets))

    def test_required_source_missing_and_source_escape_fail_read_only(self):
        source = self.root / 'shell/bin/torvus'
        source.unlink()
        with self.assertRaisesRegex(ValueError, 'Missing required'):
            self.resolve()
        outside = self.base / 'outside'
        outside.write_text('not managed')
        source.symlink_to(outside)
        with self.assertRaisesRegex(ValueError, 'escapes'):
            self.resolve()
        self.assertFalse(self.home.exists())

    def test_manifest_rejects_version_traversal_and_duplicate_targets(self):
        path = self.root / 'config/profiles.json'
        original = json.loads(path.read_text())
        for mutation in ('version', 'traversal', 'duplicate'):
            data = json.loads(json.dumps(original))
            if mutation == 'version':
                data['version'] = 99
            elif mutation == 'traversal':
                data['components']['fish']['links'][0][2] = '../escape'
            else:
                data['components']['fish']['links'].append(data['components']['fish']['links'][0])
            path.write_text(json.dumps(data))
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.resolve()
        self.assertFalse(self.home.exists())

    def test_requirements_distinguish_optional_tools_without_claiming_version_checks(self):
        requirements = self.resolve()['requirements']
        nvim = next(x for x in requirements if x['command'] == 'nvim')
        self.assertTrue(nvim['required'])
        self.assertEqual(nvim['minimum'], '0.12')
        starship = next(x for x in requirements if x['command'] == 'starship')
        self.assertFalse(starship['required'])
        self.assertTrue(all(not x['version_checked'] for x in requirements))

    def test_legacy_scopes_and_custom_config_root(self):
        self.roots['config'] = self.home / 'xdg'
        self.assertEqual({x['component'] for x in self.resolve('bin')['links']}, {'launchers'})
        rex = self.resolve('rex')['links']
        self.assertEqual(Path(rex[0]['target']), self.home / 'xdg/rex/init.lua')


if __name__ == '__main__':
    unittest.main()
