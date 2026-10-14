"""Owned symlinks, explicit adoption and recoverable per-target writes."""
from contextlib import contextmanager
import fcntl
import json
import os
import stat
from pathlib import Path
import tempfile
import uuid


def exists(path):
    return os.path.lexists(path)


def points(path, source):
    return path.is_symlink() and os.readlink(path) == source


def parents(path, roots, allowed=()):
    """Never traverse a symlink under one of the operator-selected roots."""
    anchors = sorted(roots, key=lambda p: len(p.parts), reverse=True)
    anchor = next((p for p in anchors if path.is_relative_to(p)), None)
    if anchor is None:
        raise ValueError(f'Target outside configured roots: {path}')
    current = path.parent
    while current != anchor and current != current.parent:
        if current.is_symlink() and current not in allowed:
            raise ValueError(f'Refusing symlink parent: {current}')
        if exists(current) and not current.is_dir():
            raise ValueError(f'Parent is not a directory: {current}')
        current = current.parent


def sync_parent(path):
    directory = os.open(path.parent, os.O_RDONLY)
    try:
        os.fsync(directory)
    finally:
        os.close(directory)


def save(path, data):
    fd, name = tempfile.mkstemp(prefix='.links-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            json.dump(data, stream, indent=2, sort_keys=True)
            stream.write('\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
        sync_parent(path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def load(path, root):
    if path.is_symlink():
        raise ValueError('Ownership ledger must not be a symlink')
    if not path.exists():
        return {'version': 1, 'root': str(root), 'entries': {}, 'containers': {}}
    data = json.loads(path.read_text())
    if data.get('version') != 1 or data.get('root') != str(root):
        raise ValueError('Ownership ledger belongs to another checkout or version')
    if not isinstance(data.get('entries'), dict) or not isinstance(data.get('containers'), dict):
        raise ValueError('Invalid ownership ledger')
    for target, record in list(data['entries'].items()) + list(data['containers'].items()):
        destination = Path(target)
        if not destination.is_absolute() or not isinstance(record, dict):
            raise ValueError('Invalid ownership target')
        for backup in [record.get('backup'), *record.get('older_backups', [])]:
            if backup is not None:
                candidate = Path(backup)
                if candidate.parent != destination.parent or not candidate.name.startswith(destination.name + '.bak.'):
                    raise ValueError('Invalid ownership backup path')
    return data


@contextmanager
def locked(directory, roots):
    parents(directory / 'lock', roots)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    inherited = os.environ.get('TORVUS_DOTFILES_LOCK_FD')
    if inherited is not None:
        try:
            fd = int(inherited)
            actual, expected = os.fstat(fd), (directory / 'lock').lstat()
            if (fd < 3 or not stat.S_ISREG(actual.st_mode) or actual.st_uid != os.getuid()
                    or (actual.st_dev, actual.st_ino) != (expected.st_dev, expected.st_ino)):
                raise ValueError('Inherited dotfiles lock does not match local state')
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except (OSError, ValueError) as error:
            raise ValueError('Invalid or busy inherited dotfiles lock') from error
        yield
        return
    fd = os.open(directory / 'lock', os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError('Another dotfiles operation is running') from None
        yield
    finally:
        os.close(fd)


def inspect(report, ledger, roots):
    actions, migrations = [], set()
    skill_source = str(Path(report['root']) / 'agents/skills')
    for item in report['links']:
        target = Path(item['target'])
        parent = target.parent
        if item['component'] == 'skills' and parent.is_symlink():
            if parent.resolve() != Path(skill_source).resolve():
                raise ValueError(f'Ambiguous skills directory: {parent}')
            migrations.add(parent)
        parents(target, roots, migrations)
    for item in report['links']:
        target, source = Path(item['target']), item['source']
        old = ledger['entries'].get(str(target), {})
        if target.parent in migrations or not exists(target):
            state = 'new'
        elif points(target, source):
            state = 'ok'
        elif old.get('source') and points(target, old['source']):
            state = 'changed'
        elif old.get('pending') and old.get('backup') and not exists(Path(old['backup'])):
            state = 'pending'
        else:
            state = 'foreign'
        actions.append({**item, 'status': state})
    targets = {x['target'] for x in actions}
    components = {x['component'] for x in actions}
    for target, old in ledger['entries'].items():
        if target not in targets and (report['profile'] not in ('bin', 'rex') or old['component'] in components):
            parents(Path(target), roots)
            actions.append({'target': target, **old, 'status': 'obsolete'})
    return actions, sorted(migrations)


def apply(report, path, ledger, roots, revision, adopt=False, prune=False):
    actions, migrations = inspect(report, ledger, roots)
    if not adopt and (migrations or any(x['status'] == 'foreign' for x in actions)):
        raise ValueError('Unmanaged targets need explicit --adopt; preview with --dry-run')
    # Record the backup destination before moving anything; retries never overwrite it.
    for parent in migrations:
        record = ledger['containers'].get(str(parent))
        if record is None:
            record = {'backup': str(parent) + '.bak.' + uuid.uuid4().hex}
            ledger['containers'][str(parent)] = record
            save(path, ledger)
        backup = Path(record['backup'])
        if exists(backup):
            raise ValueError(f'Legacy skills backup already exists: {backup}')
        parent.rename(backup)
        parent.mkdir()
        sync_parent(parent)
    for item in actions:
        target, source = Path(item['target']), item['source']
        if item['status'] == 'obsolete':
            if prune and points(target, source):
                target.unlink()
                sync_parent(target)
                del ledger['entries'][str(target)]
                save(path, ledger)
            continue
        previous = ledger['entries'].get(str(target), {})
        record = {k: item[k] for k in ('source', 'component')}
        record['revision'] = revision
        if previous.get('backup'):
            record['backup'] = previous['backup']
        if previous.get('older_backups'):
            record['older_backups'] = previous['older_backups']
        if not points(target, source):
            target.parent.mkdir(parents=True, exist_ok=True)
            if exists(target):
                backup = Path(previous['backup']) if previous.get('pending') and previous.get('backup') else Path(str(target) + '.bak.' + uuid.uuid4().hex)
                if exists(backup):
                    raise ValueError(f'Backup collision: {backup}')
                if previous.get('backup') and previous['backup'] != str(backup):
                    record['older_backups'] = previous.get('older_backups', []) + [previous['backup']]
                record['backup'] = str(backup)
            else:
                backup = None
            ledger['entries'][str(target)] = {**record, 'pending': True}
            save(path, ledger)
            if backup is not None:
                target.rename(backup)
            target.symlink_to(source)
            sync_parent(target)
        ledger['entries'][str(target)] = record
        if previous != record:
            save(path, ledger)
    return actions
