"""Small SSH transport; the remote owns revision resolution and reconciliation."""
import argparse
import json
import re
import subprocess
import sys

VERSION = 1
COMMANDS = ('status', 'doctor', 'reconcile', 'sync')
ENTRYPOINT = '~/.local/bin/dotfiles --remote-request'
GUIDANCE = 'Install the matching dotfiles CLI on the host and run dotfiles adopt --profile headless there once.'


def validate(request):
    if not isinstance(request, dict) or set(request) - {'version', 'command', 'revision', 'dry_run', 'scope'}:
        raise ValueError('Invalid remote dotfiles request')
    if type(request.get('version')) is not int or request['version'] != VERSION:
        raise ValueError('Remote dotfiles protocol mismatch. ' + GUIDANCE)
    if request.get('command') not in COMMANDS:
        raise ValueError('Unsupported remote dotfiles command')
    if type(request.get('dry_run', False)) is not bool or request.get('scope') not in (None, 'profile', 'all'):
        raise ValueError('Invalid remote dotfiles options')
    if request.get('scope') and request['command'] not in ('status', 'doctor'):
        raise ValueError('--scope is supported by remote status and doctor')
    revision = request.get('revision')
    if revision is not None and (request['command'] != 'sync' or not isinstance(revision, str)
                                 or not re.fullmatch(r'[0-9a-f]{40}', revision)):
        raise ValueError('--revision requires sync and a full lowercase published commit SHA')
    if request.get('dry_run') and request['command'] not in ('sync', 'reconcile'):
        raise ValueError('--dry-run is supported by remote sync and reconcile')
    return request


def receive(argv, stream=None):
    """Return local argv from the fixed entry point; no recursive hosts or paths."""
    if '--remote-request' not in argv:
        return argv
    if argv != ['--remote-request']:
        raise ValueError('--remote-request accepts only a structured stdin request')
    payload = (stream or sys.stdin).read(65537)
    if len(payload) > 65536:
        raise ValueError('Remote dotfiles request is too large')
    request = validate(json.loads(payload))
    args = [request['command'], '--json']
    if request.get('scope'):
        args.extend(['--scope', request['scope']])
    if request.get('revision'):
        args.extend(['--revision', request['revision']])
    if request.get('dry_run'):
        args.append('--dry-run')
    return args


def exchange(host, request):
    validate(request)
    if not re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9_.-]{0,252}', host):
        raise ValueError('--host must be an SSH host alias, without user, options or shell syntax')
    command = ['ssh', '-T', '-oForwardAgent=no', '-oClearAllForwardings=yes',
               '-oPermitLocalCommand=no', '--', host, ENTRYPOINT]
    process = subprocess.run(command, input=json.dumps(request) + '\n', text=True, capture_output=True)
    code = process.returncode if process.returncode >= 0 else 128 - process.returncode
    try:
        # Local CLI failures produce the same JSON schema on stderr.
        result = json.loads(process.stdout or process.stderr)
        if (not isinstance(result, dict) or type(result.get('version')) is not int
                or result['version'] != VERSION or type(result.get('healthy')) is not bool
                or not isinstance(result.get('errors', []), list)
                or any(not isinstance(x, str) for x in result.get('errors', []))):
            raise ValueError('Remote dotfiles protocol mismatch')
    except (ValueError, TypeError):
        result = {'version': VERSION, 'healthy': False, 'outcome': 'unknown', 'errors': [
            'No compatible remote response; application outcome is unknown. Check remote status before retrying. ' + GUIDANCE]}
        detail = process.stderr.strip()
        if detail:
            result['errors'].append(detail)
        return result, code or 1
    if code == 255:
        result.update(healthy=False, outcome='unknown')
        result.setdefault('errors', []).append('SSH disconnected; verify remote status before retrying.')
    elif code != 0 and result['healthy']:
        result.update(healthy=False)
        result.setdefault('errors', []).append(f'Remote command exited with status {code}')
    return result, code or (0 if result['healthy'] else 1)


def render(host, result, as_json):
    if as_json:
        print(json.dumps({'host': host, **result}, indent=2))
        return
    print(f"{host}: {result.get('profile', 'unknown profile')} — {'healthy' if result['healthy'] else 'incomplete'}")
    for key in ('applied', 'attempted', 'checked_out', 'target'):
        if result.get(key):
            print(f'{key}: {result[key]}')
    for error in result.get('errors', []):
        print(error)
    if result.get('error'):
        print(result['error'])
    for requirement in result.get('requirements', []):
        if not requirement.get('healthy', True):
            print(f"{'required' if requirement['required'] else 'optional'}: {requirement['command']}")
    for key in ('integration', 'integrations'):
        if result.get(key):
            print(f'{key}: {json.dumps(result[key])}')


def dispatch(argv):
    """Run remote-only before reading local state or staging local apply helpers."""
    if not any(arg == '--host' or arg.startswith('--host=') for arg in argv):
        return None
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=COMMANDS)
    parser.add_argument('--host', required=True)
    parser.add_argument('--revision')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--scope', choices=('all', 'profile'))
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args(argv)
    request = {'version': VERSION, 'command': args.command, 'revision': args.revision,
               'dry_run': args.dry_run, 'scope': args.scope}
    try:
        result, code = exchange(args.host, request)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        result, code = {'version': VERSION, 'healthy': False, 'errors': [str(error)]}, 1
    render(args.host, result, args.json)
    return code
