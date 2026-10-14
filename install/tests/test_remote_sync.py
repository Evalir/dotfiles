"""Exercise fixed SSH transport without contacting a host or reading real state."""
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import remote


class Remote(unittest.TestCase):
    request = {'version': 1, 'command': 'sync', 'revision': 'a' * 40, 'dry_run': True}

    def response(self, code=0, value=None, stderr=''):
        return subprocess.CompletedProcess([], code, json.dumps(value or {'version': 1, 'healthy': True}), stderr)

    def test_fixed_argv_and_structured_input(self):
        with patch.object(remote.subprocess, 'run', return_value=self.response()) as run:
            result, code = remote.exchange('torvus', self.request)
        self.assertEqual(0, code)
        self.assertTrue(result['healthy'])
        self.assertEqual(['ssh', '-T', '-oForwardAgent=no', '-oClearAllForwardings=yes',
                          '-oPermitLocalCommand=no', '--', 'torvus',
                          '~/.local/bin/dotfiles --remote-request'], run.call_args.args[0])
        self.assertEqual(self.request, json.loads(run.call_args.kwargs['input']))
        self.assertNotIn('shell', run.call_args.kwargs)

    def test_bad_aliases_revisions_and_recursive_requests_never_execute(self):
        with patch.object(remote.subprocess, 'run') as run:
            for host in ('-oProxyCommand=evil', 'user@host', 'host;echo bad', 'host/path', ''):
                with self.assertRaises(ValueError):
                    remote.exchange(host, self.request)
            for revision in ('master', 'a' * 39, 'A' * 40, 'a;reboot', ['a' * 40]):
                with self.assertRaises(ValueError):
                    remote.exchange('torvus', {**self.request, 'revision': revision})
            for extra in ({'host': 'another'}, {'root': '/tmp'}, {'profile': 'desktop'}):
                with self.assertRaises(ValueError):
                    remote.receive(['--remote-request'], io.StringIO(json.dumps({**self.request, **extra})))
        run.assert_not_called()

    def test_receiver_normalizes_only_supported_flags(self):
        args = remote.receive(['--remote-request'], io.StringIO(json.dumps(self.request)))
        self.assertEqual(['sync', '--json', '--revision', 'a' * 40, '--dry-run'], args)
        scoped = {'version': 1, 'command': 'doctor', 'scope': 'all'}
        self.assertEqual(['doctor', '--json', '--scope', 'all'],
                         remote.receive(['--remote-request'], io.StringIO(json.dumps(scoped))))
        with self.assertRaises(ValueError):
            remote.validate({**self.request, 'scope': 'profile'})
        with self.assertRaises(ValueError):
            remote.receive(['--remote-request', '--root=/other'], io.StringIO('{}'))
        with self.assertRaises(ValueError):
            remote.receive(['--remote-request'], io.StringIO('x' * 65537))

    def test_remote_failures_and_disconnect_preserve_status(self):
        failure = {'version': 1, 'healthy': False, 'applied': 'b' * 40,
                   'attempted': 'a' * 40, 'errors': ['dirty remote']}
        for status in (1, 42, 255):
            with patch.object(remote.subprocess, 'run', return_value=self.response(status, failure)):
                result, code = remote.exchange('torvus', self.request)
            self.assertEqual(status, code)
            self.assertEqual('b' * 40, result['applied'])
            if status == 255:
                self.assertEqual('unknown', result['outcome'])
        with patch.object(remote.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1, '', json.dumps(failure))):
            self.assertEqual(failure, remote.exchange('torvus', self.request)[0])

    def test_missing_cli_and_protocol_mismatch_explain_adoption(self):
        for response in (subprocess.CompletedProcess([], 127, '', 'command not found'),
                         self.response(value={'version': 2, 'healthy': True})):
            with patch.object(remote.subprocess, 'run', return_value=response):
                result, code = remote.exchange('torvus', self.request)
            self.assertNotEqual(0, code)
            self.assertEqual('unknown', result['outcome'])
            self.assertIn('adopt --profile headless', result['errors'][0])

    def test_launcher_remote_only_never_stages_or_reads_local_checkout(self):
        source = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory() as temporary:
            base = Path(temporary)
            root = base / 'dirty-checkout'
            (root / 'shell/bin').mkdir(parents=True)
            (root / 'install').mkdir()
            (root / 'unpublished').write_text('local edits stay here')
            shutil.copy2(source / 'shell/bin/dotfiles', root / 'shell/bin/dotfiles')
            shutil.copy2(source / 'install/remote.py', root / 'install/remote.py')
            # Neither sync_cli nor Git metadata exists: any local setup would fail.
            (base / 'ssh').write_text('#!' + sys.executable + '\nimport json,sys\n'
                                     'request=json.load(sys.stdin)\n'
                                     'print(json.dumps({"version":1,"healthy":True,"applied":request["revision"]}))\n')
            (base / 'ssh').chmod(0o755)
            before = sorted(str(p.relative_to(root)) for p in root.rglob('*'))
            env = {**os.environ, 'PATH': str(base) + os.pathsep + os.environ['PATH'],
                   'HOME': str(base / 'missing-home'), 'TMPDIR': str(base / 'missing-tmp')}
            result = subprocess.run([sys.executable, str(root / 'shell/bin/dotfiles'), 'sync',
                                     '--host', 'torvus', '--revision', 'a' * 40, '--json'],
                                    text=True, capture_output=True, env=env)
            self.assertEqual(0, result.returncode, result.stderr)
            self.assertEqual('a' * 40, json.loads(result.stdout)['applied'])
            self.assertEqual(before, sorted(str(p.relative_to(root)) for p in root.rglob('*')))
            self.assertEqual('local edits stay here', (root / 'unpublished').read_text())
            self.assertFalse((base / 'missing-home').exists())
