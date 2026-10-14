"""Pinned editor setup; never loads init.lua or upgrades existing tools/parsers."""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def run(*args):
    result = subprocess.run(args, text=True, capture_output=True, timeout=900)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or str(args))
    return result.stdout.strip()


def data_dir():
    base = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share')))
    if not base.is_absolute() or os.environ.get('NVIM_APPNAME', 'nvim') != 'nvim':
        raise ValueError('editor requires absolute XDG_DATA_HOME and default NVIM_APPNAME')
    return base / 'nvim'


def preflight(root):
    """Read-only safety gate, also called before changing the dotfiles checkout."""
    errors = []
    try:
        plugins = data_dir() / 'lazy'
        if plugins.is_symlink():
            errors.append(f'plugin directory is a symlink: {plugins}')
        elif plugins.exists():
            for plugin in sorted(plugins.iterdir()):
                if plugin.is_symlink():
                    errors.append(f'plugin is a symlink: {plugin}')
                elif plugin.is_dir():
                    if not (plugin / '.git').exists():
                        errors.append(f'unrecognized plugin directory: {plugin}')
                    elif run('git', '-C', str(plugin), 'status', '--porcelain', '--untracked-files=all'):
                        errors.append(f'dirty plugin checkout: {plugin}')
        # Conservatively include every Neovim of this user: process names cannot
        # reliably identify which config an already-running editor loaded.
        for line in run('ps', '-ax', '-o', 'uid=,pid=,comm=').splitlines():
            parts = line.split(None, 2)
            if len(parts) == 3 and parts[0] == str(os.getuid()) and Path(parts[2]).name == 'nvim':
                errors.append(f'close Neovim process {parts[1]} before applying dotfiles')
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        errors.append(str(error))
    return {'version': 1, 'healthy': not errors, 'errors': errors}


def lua(root, mode):
    # NONE excludes normal init, local overrides, providers and plugin autoload.
    with tempfile.TemporaryDirectory(prefix='dotfiles-editor-') as temporary:
        output = Path(temporary) / 'result.json'
        run('nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '--noplugin',
            '-l', str(Path(root) / 'install/editor.lua'), str(root), mode, str(output))
        return json.loads(output.read_text())


def check(root, apply=False):
    """Return versioned readiness. apply requires the caller's dotfiles lock."""
    root = Path(root).resolve()
    result = {'version': 1, 'healthy': False, 'errors': [], 'lock_hash': None}
    try:
        if apply:
            result['errors'] = preflight(root)['errors']
            if result['errors']:
                return result
        lock_bytes = (root / 'editors/nvim/lazy-lock.json').read_bytes()
        result['lock_hash'] = hashlib.sha256(lock_bytes).hexdigest()
        lock = json.loads(lock_bytes)
        manifest = lua(root, 'manifest')
        if manifest.get('errors'):
            raise RuntimeError('; '.join(manifest['errors']))
        unlocked = set(manifest['plugins']) - set(lock)
        if unlocked:
            raise ValueError('plugins missing from lazy-lock: ' + ', '.join(sorted(unlocked)))
        plugins = data_dir() / 'lazy'
        for name, entry in lock.items():
            sha = entry.get('commit', '')
            repo = manifest['plugins'].get(name)
            if not re.fullmatch(r'[A-Za-z0-9_.-]+', name) or not re.fullmatch(r'[0-9a-f]{40}', sha):
                raise ValueError(f'invalid plugin lock entry: {name}')
            if not repo or not re.fullmatch(r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+', repo):
                raise ValueError(f'no declared repository for locked plugin: {name}')
            target = plugins / name
            if target.is_symlink():
                raise ValueError(f'plugin is a symlink: {target}')
            if apply and not target.exists():
                plugins.mkdir(parents=True, exist_ok=True)
                with tempfile.TemporaryDirectory(prefix='.dotfiles-', dir=plugins) as staging:
                    clone = Path(staging) / name
                    run('git', 'clone', '--filter=blob:none', '--no-checkout',
                        f'https://github.com/{repo}.git', str(clone))
                    run('git', '-C', str(clone), 'fetch', 'origin', sha)
                    run('git', '-C', str(clone), 'checkout', '--detach', sha)
                    clone.rename(target)
            if target.exists() and run('git', '-C', str(target), 'status', '--porcelain', '--untracked-files=all'):
                raise ValueError(f'dirty plugin checkout: {target}')
            current = run('git', '-C', str(target), 'rev-parse', 'HEAD') if target.exists() else None
            if current != sha:
                if not apply:
                    result['errors'].append(f'{name}: expected locked commit {sha}, found {current or "missing"}')
                    continue
                run('git', '-C', str(target), 'fetch', 'origin', sha)
                run('git', '-C', str(target), 'checkout', '--detach', sha)
            # The only native optional plugin build declared in this profile.
            if (apply and manifest['builds'].get(name) == 'make' and shutil.which('make')
                    and (current != sha or not (target / 'build/libfzf.so').exists())):
                run('make', '-C', str(target))
        if not result['errors']:
            result['errors'].extend(lua(root, 'apply' if apply else 'check')['errors'])
        if (root / 'editors/nvim/lazy-lock.json').read_bytes() != lock_bytes:
            result['errors'].append('plugin lock changed during readiness check')
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.TimeoutExpired) as error:
        result['errors'].append(str(error))
    result['healthy'] = not result['errors']
    return result
