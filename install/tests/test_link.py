"""Run the public linker with isolated homes and configuration roots."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class Linker(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name).resolve()
        self.repo = self.base / 'repo'
        self.repo.mkdir()
        for name in ('config', 'install', 'shell', 'editors', 'agents'):
            shutil.copytree(ROOT / name, self.repo / name, ignore=shutil.ignore_patterns('__pycache__'))
        self.home = self.base / 'home'
        self.home.mkdir()
        self.config = self.home / 'custom-config'
        self.state = self.home / 'custom-state'
        self.env = {**os.environ, 'HOME': str(self.home), 'XDG_CONFIG_HOME': str(self.config),
                    'XDG_STATE_HOME': str(self.state), 'PYTHONDONTWRITEBYTECODE': '1'}

    def run_link(self, *args, ok=True):
        result = subprocess.run(['bash', str(self.repo / 'install/link.sh'), *args],
                                cwd=self.base, env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, ok, result.stderr)
        return result

    def test_preview_has_no_side_effects_and_headless_rerun_preserves_foreign_skills(self):
        preview = json.loads(self.run_link('--profile', 'headless', '--dry-run', '--json').stdout)
        self.assertFalse(self.config.exists())
        self.assertFalse(self.state.exists())
        self.assertFalse(preview['readiness_checked'])
        foreign = self.home / '.agents/skills/vendor/SKILL.md'
        foreign.parent.mkdir(parents=True)
        foreign.write_text('unrelated')
        self.run_link('--profile', 'headless')
        ledger = self.state / 'dotfiles/links.json'
        mtime = ledger.stat().st_mtime_ns
        self.run_link('--profile', 'headless')
        self.assertEqual(ledger.stat().st_mtime_ns, mtime)
        self.assertEqual(foreign.read_text(), 'unrelated')
        self.assertFalse((self.config / 'rex').exists())
        self.assertTrue((self.config / 'nvim').is_symlink())
        (self.home / '.codex').mkdir()
        self.run_link('--profile', 'headless')
        self.assertTrue((self.home / '.codex/skills/plan-spec').is_symlink())
        self.assertFalse((self.home / '.claude').exists())

    def test_explicit_adoption_preserves_config_and_host_overrides(self):
        nvim = self.config / 'nvim'
        nvim.mkdir(parents=True)
        (nvim / 'init.lua').write_text('old config')
        local = self.config / 'fish/conf.d/zz-torvus.fish'
        local.parent.mkdir(parents=True)
        local.write_text('host policy')
        self.run_link('--profile', 'headless', ok=False)
        self.assertFalse((self.home / '.local/bin/torvus').exists())
        self.run_link('--profile', 'headless', '--adopt')
        self.assertEqual(next(self.config.glob('nvim.bak.*/init.lua')).read_text(), 'old config')
        self.assertEqual(local.read_text(), 'host policy')
        self.assertTrue(nvim.is_symlink())

    def test_missing_required_source_fails_before_state_and_legacy_modes_remain_scoped(self):
        (self.repo / 'shell/fish/conf.d/evalir.fish').unlink()
        self.run_link('--profile', 'headless', ok=False)
        self.assertFalse(self.state.exists())
        self.run_link('--bin')
        self.assertTrue((self.home / '.local/bin/torvus').is_symlink())
        self.assertFalse(self.config.exists())
        self.run_link('--rex')
        self.assertTrue((self.config / 'rex/init.lua').is_symlink())
        self.assertFalse((self.config / 'fish').exists())

    def test_default_desktop_and_new_skill_after_prior_install(self):
        self.run_link()
        self.assertTrue((self.config / 'rex/init.lua').is_symlink())
        source = self.repo / 'agents/skills/new-skill'
        source.mkdir()
        (source / 'SKILL.md').write_text('new published skill')
        self.run_link('--profile', 'headless')
        self.assertTrue((self.home / '.agents/skills/new-skill').is_symlink())
        self.assertTrue((self.config / 'rex/init.lua').is_symlink())
        self.run_link('--profile', 'headless', '--prune')
        self.assertFalse((self.config / 'rex/init.lua').exists())


if __name__ == '__main__':
    unittest.main()
