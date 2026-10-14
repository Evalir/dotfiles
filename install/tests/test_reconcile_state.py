"""Use a real disposable remote to exercise publication and journal boundaries."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import reconcile_state as state


class State(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.base = Path(self.tmp.name).resolve()
        self.remote, self.root = self.base / 'remote.git', self.base / 'checkout'
        subprocess.run(['git', 'init', '--bare', str(self.remote)], check=True, capture_output=True)
        subprocess.run(['git', 'clone', str(self.remote), str(self.root)], check=True, capture_output=True)
        for key, value in [('user.email', 'test@example.test'), ('user.name', 'Test'), ('commit.gpgsign', 'false')]:
            state.git(self.root, 'config', key, value)
        state.git(self.root, 'checkout', '-b', 'master')
        (self.root / 'file').write_text('one')
        self.first = self.commit()
        state.git(self.root, 'push', 'origin', 'master')

    def commit(self):
        state.git(self.root, 'add', '.')
        state.git(self.root, 'commit', '-m', 'fixture')
        return state.git(self.root, 'rev-parse', 'HEAD').stdout.strip()

    def test_published_detached_and_manual_pull_are_accepted(self):
        self.assertEqual(state.checkout_policy(self.root), self.first)
        state.git(self.root, 'checkout', '--detach', self.first)
        self.assertEqual(state.checkout_policy(self.root), self.first)
        with self.assertRaisesRegex(ValueError, 'full lowercase'):
            state.published(self.root, 'master')

    def test_dirty_local_only_and_feature_branch_refused(self):
        (self.root / 'file').write_text('local')
        with self.assertRaisesRegex(ValueError, 'local changes'):
            state.checkout_policy(self.root)
        second = self.commit()
        with self.assertRaisesRegex(ValueError, 'not published'):
            state.checkout_policy(self.root)
        state.git(self.root, 'push', 'origin', 'master')
        state.git(self.root, 'checkout', '-b', 'feature')
        with self.assertRaisesRegex(ValueError, 'Feature branches'):
            state.checkout_policy(self.root)
        self.assertEqual(state.published(self.root, second), second)

    def test_journal_never_infers_success_from_attempt(self):
        path = self.base / 'state.json'
        data = state.registration(self.root, 'headless')
        state.begin(path, data, self.first)
        interrupted = state.read(path, self.root)
        self.assertIsNone(interrupted['applied'])
        self.assertEqual(interrupted['phase'], 'applying')
        state.finish(path, data, self.first, self.root, {'links': True})
        state.begin(path, data, 'b' * 40)
        self.assertEqual(state.read(path, self.root)['applied'], self.first)
        state.finish(path, data, 'b' * 40, self.root, {'links': True})
        self.assertEqual(state.read(path, self.root)['previous'], self.first)
        with self.assertRaisesRegex(ValueError, 'another checkout'):
            state.read(path, self.base)

    def test_missing_and_old_required_tools_are_reported(self):
        tool = self.base / 'tmux'
        tool.write_text('#!/bin/sh\nprintf "tmux 2.9\\n"\n')
        tool.chmod(0o755)
        result = state.requirements({'requirements': [
            {'command': 'tmux', 'executable': str(tool), 'minimum': '3.1', 'required': True},
            {'command': 'optional', 'executable': None, 'required': False}]})
        self.assertFalse(result[0]['healthy'])
        self.assertTrue(result[0]['version_checked'])
        self.assertFalse(result[1]['healthy'])


if __name__ == '__main__':
    unittest.main()
