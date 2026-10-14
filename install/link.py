#!/usr/bin/env python3
"""Link a portable profile; explicitly adopt conflicts, never install packages."""
import argparse
import json
import subprocess
import sys

sys.dont_write_bytecode = True
from profile import ROOT, environment, resolve
from ownership import apply, inspect, load, locked, parents


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument('--profile', choices=('headless', 'desktop'))
    selection.add_argument('--bin', action='store_true')
    selection.add_argument('--rex', action='store_true')
    parser.add_argument('--dry-run', action='store_true', help='Inspect without writing files or state')
    parser.add_argument('--adopt', action='store_true', help='Back up foreign targets before linking')
    parser.add_argument('--prune', action='store_true', help='Remove only obsolete links still owned by us')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args()
    profile = 'bin' if args.bin else 'rex' if args.rex else args.profile or 'desktop'
    roots = environment()
    report = resolve(profile, ROOT, roots)
    path = roots['state'] / 'dotfiles/links.json'
    parents(path, roots.values())
    ledger = load(path, ROOT)
    if args.dry_run:
        actions, migrations = inspect(report, ledger, roots.values())
    else:
        with locked(path.parent, roots.values()):
            ledger = load(path, ROOT)
            # Preflight every target before changing any of them.
            actions, migrations = inspect(report, ledger, roots.values())
            revision = subprocess.run(['git', '-C', str(ROOT), 'rev-parse', 'HEAD'],
                                      capture_output=True, text=True)
            apply(report, path, ledger, roots.values(),
                  revision.stdout.strip() if revision.returncode == 0 else None,
                  adopt=args.adopt, prune=args.prune)
    result = {**report, 'actions': actions, 'legacy_skill_directories': [str(x) for x in migrations],
              'dry_run': args.dry_run, 'readiness_checked': False}
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        for directory in migrations:
            action = 'requires adoption' if args.dry_run else 'adopted'
            print(f'legacy skills directory {action}: {directory}')
        for action in actions:
            print(f"{action['status']:8} {action['target']}")
        for item in report['skipped']:
            print(f"optional source not published: {item['source']}")
        for item in report['requirements']:
            if not item['executable']:
                kind = 'required' if item['required'] else 'optional'
                print(f"missing {kind} tool: {item['command']}")
        print('Links only; binary versions and editor readiness have not been checked.')


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f'Link error: {error}', file=sys.stderr)
        sys.exit(1)
