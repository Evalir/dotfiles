"""Exercise the public staged launcher against a disposable published remote."""
import json
import fcntl
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[2]


class CliWorkflow(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.base = Path(temporary.name).resolve()
        self.home, self.author, self.root = [self.base / name for name in ('home', 'author', 'checkout')]
        self.home.mkdir()
        self.env = {**os.environ, 'HOME': str(self.home), 'XDG_CONFIG_HOME': str(self.home / '.config'),
                    'XDG_STATE_HOME': str(self.home / '.state'), 'XDG_DATA_HOME': str(self.home / '.data'),
                    'GIT_CONFIG_GLOBAL': str(self.home / '.gitconfig'), 'GIT_CONFIG_NOSYSTEM': '1',
                    'PYTHONDONTWRITEBYTECODE': '1', 'GIT_TERMINAL_PROMPT': '0'}
        self.env.pop('TORVUS_DOTFILES_LOCK_FD', None)
        self.remote = self.base / 'remote.git'
        self.git(self.base, 'init', '--bare', str(self.remote))
        self.git(self.base, 'clone', str(self.remote), str(self.author))
        self.git(self.author, 'checkout', '-b', 'master')
        for name, value in [('user.email', 'fixture@example.test'), ('user.name', 'Fixture'), ('commit.gpgsign', 'false')]:
            self.git(self.author, 'config', name, value)
        for directory in ('install', 'shell/bin', 'config'):
            (self.author / directory).mkdir(parents=True)
        for source in (SOURCE / 'install').glob('*.py'):
            shutil.copy2(source, self.author / 'install' / source.name)
        shutil.copy2(SOURCE / 'shell/bin/dotfiles', self.author / 'shell/bin/dotfiles')
        self.helper('old')
        self.manifest = {'version': 1, 'profiles': {'headless': ['fixture']}, 'components': {'fixture': {
            'links': [['file', 'config', 'fixture'], ['shell/bin/dotfiles', 'home', '.local/bin/dotfiles']],
            'required': [{'command': 'dotfiles-fixture-tool', 'minimum': '1.0'}]}}}
        (self.author / 'config/profiles.json').write_text(json.dumps(self.manifest))
        (self.author / 'file').write_text('old')
        self.first = self.publish()
        self.git(self.base, 'clone', str(self.remote), str(self.root))
        self.directory = self.home / '.state/dotfiles'
        self.toolbin = self.base / 'tools'
        self.toolbin.mkdir()
        self.env['PATH'] = str(self.toolbin) + os.pathsep + os.environ['PATH']

    def git(self, root, *args):
        return subprocess.run(['git', '-C', str(root), *args], check=True, env=self.env,
                              capture_output=True, text=True).stdout.strip()

    def helper(self, token):
        (self.author / 'install/editor.py').write_text(
            "from pathlib import Path\n"
            "def preflight(root): return {'healthy': True, 'errors': []}\n"
            "def check(root, apply=False):\n"
            "    assert Path(__file__).parent != Path(root) / 'install', 'helper was not staged'\n"
            f"    return {{'healthy': True, 'errors': [], 'helper': {token!r}}}\n")

    def publish(self):
        self.git(self.author, 'add', '.')
        self.git(self.author, 'commit', '-m', 'fixture')
        self.git(self.author, 'push', 'origin', 'master')
        return self.git(self.author, 'rev-parse', 'HEAD')

    def cli(self, *args, code=0):
        result = subprocess.run([sys.executable, str(self.root / 'shell/bin/dotfiles'), '--json', *args],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, code, result.stdout + result.stderr)
        return json.loads(result.stdout or result.stderr)

    def tool(self):
        path = self.toolbin / 'dotfiles-fixture-tool'
        path.write_text('#!/bin/sh\nprintf "fixture 1.0\\n"\n')
        path.chmod(0o755)

    def test_public_self_update_preview_hook_rollback_and_exact_revision(self):
        self.cli('adopt', '--dry-run', code=1)
        self.assertFalse(self.directory.exists())
        self.assertFalse((self.home / '.config').exists())
        self.assertEqual(self.cli('adopt', code=1)['phase'], 'incomplete')
        hook = self.base / 'hook'
        hook.write_text(f'#!{sys.executable}\nfrom pathlib import Path\np=Path({str(self.base / "hook-log")!r})\np.write_text(p.read_text()+"run\\n" if p.exists() else "run\\n")\n')
        hook.chmod(0o755)
        self.cli('register-hook', '--hook', str(hook), code=1)
        self.assertFalse((self.base / 'hook-log').exists())
        self.tool()
        self.assertEqual(self.cli('reconcile')['applied'], self.first)
        self.helper('new')
        (self.author / 'file').write_text('new')
        # Replace the launcher too; the running process must finish with its staged helpers.
        with (self.author / 'shell/bin/dotfiles').open('a') as stream:
            stream.write('\n# new published launcher\n')
        second = self.publish()
        before = (self.directory / 'state.json').read_bytes()
        preview = self.cli('sync', '--dry-run')
        self.assertEqual(preview['target'], second)
        self.assertEqual((self.directory / 'state.json').read_bytes(), before)
        self.assertEqual((self.home / '.config/fixture').read_text(), 'old')
        synced = self.cli('sync')
        self.assertEqual(synced['applied'], second)
        self.assertEqual(synced['components']['editor']['helper'], 'old')
        self.assertEqual(self.cli('reconcile')['components']['editor']['helper'], 'new')
        adopted = self.cli('adopt', code=1)
        self.assertEqual(adopted['integration']['status'], 'pending')
        self.assertEqual((self.base / 'hook-log').read_text().count('run\n'), 3)
        self.assertTrue(self.cli('status', '--scope', 'profile')['healthy'])
        self.assertTrue(self.cli('retry-hook')['healthy'])
        target = self.home / '.config/fixture'
        target.unlink()
        target.write_text('local override')
        refused = self.cli('rollback', code=1)
        self.assertIn('Foreign links', refused['errors'][0])
        self.assertEqual(target.read_text(), 'local override')
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), second)
        target.unlink()
        target.symlink_to(self.root / 'file')
        exact = self.cli('sync', '--revision', self.first)
        self.assertEqual(exact['applied'], self.first)
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), self.first)
        self.assertEqual(self.git(self.root, 'rev-parse', 'master'), second)
        self.assertEqual(self.cli('rollback')['applied'], second)
        self.assertTrue(self.cli('doctor', '--scope', 'profile')['healthy'])
        journal = json.loads((self.directory / 'state.json').read_text())
        journal.update(phase='applying', attempted=self.first)
        (self.directory / 'state.json').write_text(json.dumps(journal))
        self.assertFalse(self.cli('status', '--scope', 'profile', code=1)['healthy'])
        self.assertEqual((self.base / 'hook-log').read_text().count('run\n'), 6)

    def test_diverged_local_commit_is_refused_without_reset(self):
        self.tool()
        self.cli('adopt')
        self.git(self.root, 'config', 'user.name', 'Fixture')
        self.git(self.root, 'config', 'user.email', 'fixture@example.test')
        self.git(self.root, 'config', 'commit.gpgsign', 'false')
        (self.root / 'file').write_text('local commit')
        self.git(self.root, 'commit', '-am', 'local')
        local = self.git(self.root, 'rev-parse', 'HEAD')
        (self.author / 'file').write_text('remote commit')
        self.publish()
        self.assertIn('not published', self.cli('sync', code=1)['errors'][0])
        self.assertEqual(self.git(self.root, 'rev-parse', 'HEAD'), local)
        self.assertEqual((self.root / 'file').read_text(), 'local commit')

    def test_stale_staged_helpers_refuse_before_applying_new_checkout(self):
        self.tool()
        self.cli('adopt')
        staged = self.base / 'staged'
        shutil.copytree(self.root / 'install', staged)
        self.helper('new')
        self.publish()
        self.git(self.root, 'pull', '--ff-only')
        before = (self.directory / 'state.json').read_bytes()
        result = subprocess.run([sys.executable, str(staged / 'sync_cli.py'), '--root', str(self.root),
                                 'reconcile', '--json'], env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn('changed while staging', json.loads(result.stderr)['errors'][0])
        self.assertEqual((self.directory / 'state.json').read_bytes(), before)
        self.assertTrue(self.cli('reconcile')['healthy'])

    def test_inherited_lock_reaches_hook_and_nested_readonly_launcher(self):
        self.tool()
        self.cli('adopt')
        hook = self.base / 'hook'
        hook.write_text(f'#!{sys.executable}\nimport os, subprocess, sys\n'
                        'fd = int(os.environ["TORVUS_DOTFILES_LOCK_FD"])\nos.fstat(fd)\n'
                        f'subprocess.run([sys.executable, {str(self.root / "shell/bin/dotfiles")!r}, '
                        '"doctor", "--scope", "profile", "--json"], pass_fds=(fd,), check=True)\n')
        hook.chmod(0o755)
        self.cli('register-hook', '--hook', str(hook), code=1)
        fd = os.open(self.directory / 'lock', os.O_RDWR)
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            result = subprocess.run([sys.executable, str(self.root / 'shell/bin/dotfiles'),
                                     'retry-hook', '--json'], pass_fds=(fd,), capture_output=True, text=True,
                                    env={**self.env, 'TORVUS_DOTFILES_LOCK_FD': str(fd)})
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue(json.loads(result.stdout)['integration']['healthy'])
        finally:
            os.close(fd)
