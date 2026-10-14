"""One explicitly registered host hook; shared health never depends on the hook."""
import os
from pathlib import Path
import subprocess

from ownership import save


def register(path, data, argv):
    if not argv or not Path(argv[0]).is_absolute() or not os.access(argv[0], os.X_OK):
        raise ValueError('Hook must name an existing absolute executable followed by its arguments')
    if any('\0' in item for item in argv):
        raise ValueError('Invalid hook argument')
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
        result = subprocess.run(data['hook'], capture_output=True, text=True, timeout=900)
        # Never persist hook output; it may contain machine-local information.
        data['integration'].update(healthy=result.returncode == 0, status='complete', exit_code=result.returncode)
    except (OSError, subprocess.TimeoutExpired) as error:
        data['integration'].update(status='failed', error=type(error).__name__)
    save(path, data)


def overall(data):
    return data['phase'] == 'healthy' and (not data.get('hook') or bool((data.get('integration') or {}).get('healthy')))
