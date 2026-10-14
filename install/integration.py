"""One explicitly registered host hook; shared health never depends on the hook."""
import os
from pathlib import Path
import subprocess
import stat

from ownership import save


def register(path, data, argv):
    if not argv or not Path(argv[0]).is_absolute() or not os.access(argv[0], os.X_OK):
        raise ValueError('Hook must name an existing absolute executable followed by its arguments')
    if any('\0' in item for item in argv):
        raise ValueError('Invalid hook argument')
    if data.get('hook') == list(argv):
        return
    data['hook'] = list(argv)
    data['integration'] = {'healthy': False, 'status': 'pending'}
    save(path, data)


def run(path, data):
    if not data.get('hook'):
        return
    if data['phase'] != 'healthy' or data['attempted'] != data['applied']:
        raise ValueError('Reconcile the shared profile successfully before running its integration')
    data['integration'] = {'healthy': False, 'status': 'running', 'revision': data['applied']}
    save(path, data)
    try:
        descriptors = ()
        inherited = os.environ.get('TORVUS_DOTFILES_LOCK_FD')
        if inherited is not None:
            fd = int(inherited)
            actual, expected = os.fstat(fd), (path.parent / 'lock').lstat()
            if (fd < 3 or not stat.S_ISREG(actual.st_mode) or actual.st_uid != os.getuid()
                    or (actual.st_dev, actual.st_ino) != (expected.st_dev, expected.st_ino)):
                raise ValueError('Inherited lock does not match the integration state')
            descriptors = (fd,)
        result = subprocess.run(data['hook'], capture_output=True, text=True, timeout=900,
                                pass_fds=descriptors)
        # Never persist hook output; it may contain machine-local information.
        data['integration'].update(healthy=result.returncode == 0, status='complete', exit_code=result.returncode)
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        data['integration'].update(status='failed', error=type(error).__name__)
    save(path, data)


def overall(data):
    return data['phase'] == 'healthy' and (not data.get('hook') or (bool((data.get('integration') or {}).get('healthy'))
            and data['integration'].get('revision') == data.get('applied')))
