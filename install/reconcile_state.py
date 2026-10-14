"""Published Git revisions and the small per-host application journal."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

from ownership import save


def git(root, *args, check=True):
    result = subprocess.run(['git', '-C', str(root), *args], text=True, capture_output=True)
    if check and result.returncode:
        raise ValueError(result.stderr.strip() or 'Git command failed')
    return result


def clean(root):
    if git(root, 'status', '--porcelain', '--untracked-files=all').stdout:
        raise ValueError('Checkout has local changes; commit/push or review them manually')


def published(root, revision=None):
    revision = revision or git(root, 'rev-parse', 'HEAD').stdout.strip()
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ValueError('Revision must be a full lowercase Git SHA')
    if git(root, 'merge-base', '--is-ancestor', revision, 'refs/remotes/origin/master', check=False).returncode:
        raise ValueError('Revision is not published on origin/master; push it manually first')
    return revision


def checkout_policy(root):
    clean(root)
    branch = git(root, 'symbolic-ref', '--quiet', '--short', 'HEAD', check=False).stdout.strip()
    if branch not in ('', 'master'):
        raise ValueError('Feature branches are not managed; use a dedicated checkout')
    return published(root)


def read(path, root):
    if path.is_symlink():
        raise ValueError('Registration must not be a symlink')
    if not path.exists():
        raise ValueError('Checkout is not registered; run dotfiles adopt --profile headless')
    data = json.loads(path.read_text())
    if data.get('version') != 1 or data.get('root') != str(root):
        raise ValueError('Registration belongs to another checkout or version')
    if data.get('profile') not in ('headless', 'desktop'):
        raise ValueError('Invalid registered profile')
    return data


def registration(root, profile):
    return {'version': 1, 'root': str(root), 'profile': profile,
            'attempted': None, 'applied': None, 'previous': None,
            'phase': 'adopted', 'components': {}, 'integration': None}


def lock_hash(root):
    path = root / 'editors/nvim/lazy-lock.json'
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def begin(path, data, revision):
    data.update(attempted=revision, phase='applying', error=None)
    if data.get('hook'):
        data['integration'] = {'healthy': False, 'status': 'pending', 'revision': revision}
    save(path, data)


def finish(path, data, revision, root, components):
    if data['applied'] != revision:
        data['previous'] = data['applied']
    data.update(applied=revision, phase='healthy', error=None,
                lock_hash=lock_hash(root), components=components)
    save(path, data)


def requirements(report):
    """Only versioned prerequisites execute; optional gaps remain informational."""
    results = []
    for item in report['requirements']:
        result = dict(item, healthy=bool(item['executable']))
        if item['executable'] and item.get('minimum'):
            flag = '-V' if item['command'] == 'tmux' else '--version'
            try:
                output = subprocess.run([item['executable'], flag], capture_output=True,
                                        text=True, timeout=10)
                match = re.search(r'(\d+)\.(\d+)(?:\.(\d+))?', output.stdout + output.stderr)
                minimum = tuple(int(n) for n in item['minimum'].split('.'))
                found = tuple(int(n or 0) for n in match.groups()) if match else ()
                result.update(version_checked=True, detected=match.group(0) if match else None,
                              healthy=output.returncode == 0 and found >= minimum)
            except (OSError, subprocess.TimeoutExpired) as error:
                result.update(healthy=False, error=str(error))
        results.append(result)
    return results
