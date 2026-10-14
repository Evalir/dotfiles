import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import integration
import reconcile_state as state


class Integration(unittest.TestCase):
    def test_failure_preserves_shared_health_and_retry_does_not_apply(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            path, hook = root / 'state.json', root / 'hook'
            hook.write_text('#!/bin/sh\nexit 7\n')
            hook.chmod(0o755)
            data = state.registration(root, 'headless')
            data.update(phase='healthy', attempted='a' * 40, applied='a' * 40)
            integration.register(path, data, [str(hook), 'literal;argument'])
            integration.run(path, data)
            self.assertEqual(data['phase'], 'healthy')
            self.assertEqual(data['applied'], 'a' * 40)
            self.assertEqual(data['integration']['exit_code'], 7)
            self.assertFalse(integration.overall(data))
            hook.write_text('#!/bin/sh\nexit 0\n')
            integration.run(path, data)
            self.assertTrue(integration.overall(data))
            self.assertEqual(json.loads(path.read_text())['hook'], [str(hook), 'literal;argument'])
            data['phase'] = 'applying'
            with self.assertRaisesRegex(ValueError, 'successfully'):
                integration.run(path, data)

    def test_registration_never_accepts_shell_text_or_missing_program(self):
        with self.assertRaisesRegex(ValueError, 'absolute executable'):
            integration.register(Path('/unused'), {}, ['echo ok; rm anything'])


if __name__ == '__main__':
    unittest.main()
