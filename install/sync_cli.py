#!/usr/bin/env python3
"""Reconcile a registered, published dotfiles checkout."""
import argparse
import io
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile

sys.dont_write_bytecode = True
from profile import environment, resolve
from ownership import apply, inspect, load, locked, parents, save
import reconcile_state as state
import editor


def snapshot(root, revision, destination):
    archive = subprocess.run(['git', '-C', str(root), 'archive', revision], check=True, capture_output=True)
    with tarfile.open(fileobj=io.BytesIO(archive.stdout)) as stream:
        for member in stream.getmembers():
            path = Path(member.name)
            if path.is_absolute() or '..' in path.parts or not (member.isfile() or member.isdir()):
                raise ValueError(f'Unsupported source archive member: {member.name}')
        stream.extractall(destination)


def report_for(root, selected, profile, roots):
    report = resolve(profile, selected, roots)
    report['root'] = str(root)
    for link in report['links']:
        link['source'] = str(root / Path(link['source']).relative_to(selected))
    report['requirements'] = state.requirements(report)
    return report


def status(root, data, report, ledger, roots, doctor=False):
    actions, migrations = inspect(report, ledger, roots.values())
    problems = []
    try:
        head = state.checkout_policy(root)
    except ValueError as error:
        head, problems = state.git(root, 'rev-parse', 'HEAD').stdout.strip(), [str(error)]
    if head != data['applied'] or data['phase'] != 'healthy':
        problems.append('Checked-out revision has not completed reconciliation')
    if migrations or any(x['status'] not in ('ok', 'obsolete') for x in actions):
        problems.append('Managed links need reconciliation')
    if any(x['required'] and not x['healthy'] for x in report['requirements']):
        problems.append('Required tools are missing or incompatible')
    health = editor.check(root) if doctor and 'nvim' in {x['component'] for x in report['links']} else None
    if health and not health['healthy']:
        problems.extend(health['errors'])
    return {**data, 'checked_out': head, 'requirements': report['requirements'],
            'actions': actions, 'editor': health, 'healthy': not problems, 'errors': problems}


def operate(root, args, roots, directory):
    path, ledger_path = directory / 'state.json', directory / 'links.json'
    data = state.read(path, root) if path.exists() else None
    if data and data.get('origin') != state.git(root, 'remote', 'get-url', 'origin').stdout.strip():
        raise ValueError('Registered origin changed; review it before adopting a new checkout')
    if args.command == 'adopt':
        if data and data['profile'] != args.profile:
            raise ValueError('Adoption cannot silently change the registered profile')
        data = data or state.registration(root, args.profile)
        data['origin'] = state.git(root, 'remote', 'get-url', 'origin').stdout.strip()
    elif data is None:
        raise ValueError('Run dotfiles adopt --profile headless first')
    ledger = load(ledger_path, root)
    report = report_for(root, root, data['profile'], roots)
    if args.command == 'requirements':
        return {'version': 1, 'profile': data['profile'], 'requirements': report['requirements'], 'healthy': True}
    if args.command in ('status', 'doctor'):
        return status(root, data, report, ledger, roots, args.command == 'doctor')
    current = state.checkout_policy(root)
    if args.command == 'sync':
        state.git(root, 'fetch', 'origin', '+refs/heads/master:refs/remotes/origin/master')
        # A force-push may have made the current checkout unpublished.
        state.published(root, current)
        revision = state.published(root, args.revision or state.git(root, 'rev-parse', 'origin/master').stdout.strip())
    elif args.command == 'rollback':
        if not data.get('previous'):
            raise ValueError('No successfully applied previous revision is recorded')
        revision = state.published(root, data['previous'])
    else:
        revision = current
    with tempfile.TemporaryDirectory(prefix='dotfiles-preview-') as staging:
        selected = Path(staging)
        snapshot(root, revision, selected)
        report = report_for(root, selected, data['profile'], roots)
        actions, migrations = inspect(report, ledger, roots.values())
        missing = [x for x in report['requirements'] if x['required'] and not x['healthy']]
        result = {'version': 1, 'profile': data['profile'], 'checked_out': current,
                  'target': revision, 'applied': data['applied'], 'actions': actions,
                  'requirements': report['requirements'], 'dry_run': args.dry_run, 'healthy': not missing}
        if args.dry_run:
            return result
        if args.command != 'adopt' and missing:
            raise ValueError('Install required tools before applying: ' + ', '.join(x['command'] for x in missing))
        if args.command != 'adopt' and (migrations or any(x['status'] == 'foreign' for x in actions)):
            raise ValueError('Foreign links need explicit adoption; preview dotfiles adopt --dry-run')
        preflight = editor.preflight(root)
        if not preflight['healthy']:
            raise ValueError('; '.join(preflight['errors']))
        state.begin(path, data, revision)
        try:
            if revision != current:
                branch = state.git(root, 'symbolic-ref', '--quiet', '--short', 'HEAD', check=False).stdout.strip()
                if branch == 'master' and args.command != 'rollback':
                    state.git(root, 'merge', '--ff-only', revision)
                else:
                    state.git(root, 'checkout', '--detach', revision)
            apply(report, ledger_path, ledger, roots.values(), revision,
                  adopt=args.command == 'adopt', prune=True)
            health = editor.check(root, apply=args.command != 'adopt')
            components = {'links': True, 'requirements': not missing, 'editor': health}
            if missing or not health['healthy']:
                data.update(phase='incomplete', components=components, error='Profile prerequisites or editor incomplete')
                save(path, data)
            else:
                state.finish(path, data, revision, root, components)
        except Exception as error:
            data.update(phase='incomplete', error=str(error))
            save(path, data)
            raise
    return {**data, 'requirements': report['requirements'], 'healthy': data['phase'] == 'healthy'}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, required=True, help=argparse.SUPPRESS)
    parser.add_argument('command', choices=('adopt', 'status', 'doctor', 'requirements', 'reconcile', 'sync', 'rollback'))
    parser.add_argument('--profile', choices=('headless', 'desktop'), default='headless')
    parser.add_argument('--scope', choices=('profile',), default='profile')
    parser.add_argument('--revision')
    parser.add_argument('--dry-run', action='store_true')
    parser.add_argument('--json', action='store_true')
    args = parser.parse_args(argv)
    root, roots = args.root.resolve(), environment()
    directory = roots['state'] / 'dotfiles'
    if args.revision and args.command != 'sync':
        raise ValueError('--revision is only supported by sync')
    parents(directory / 'state.json', roots.values())
    if args.dry_run or args.command in ('status', 'doctor', 'requirements'):
        result = operate(root, args, roots, directory)
    else:
        with locked(directory, roots.values()):
            result = operate(root, args, roots, directory)
    if args.json:
        print(json.dumps(result, indent=2))
    else:
        print(f"{result['profile']}: {'healthy' if result['healthy'] else 'incomplete'}")
        print(f"applied: {result.get('applied') or 'none'}")
        if result.get('target'):
            print(f"target: {result['target']}")
        for error in result.get('errors', []):
            print(error)
        for item in result.get('requirements', []):
            if not item['healthy']:
                print(f"{'required' if item['required'] else 'optional'}: {item['command']}")
    return 0 if result['healthy'] else 1


if __name__ == '__main__':
    try:
        sys.exit(main())
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(json.dumps({'version': 1, 'healthy': False, 'errors': [str(error)]}), file=sys.stderr)
        sys.exit(1)
