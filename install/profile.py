#!/usr/bin/env python3
"""Resolve portable profiles without installing tools or modifying the home."""
import argparse
import json
import os
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
HARNESSES = ('.cursor', '.claude', '.codex')


def inside(root, relative):
    path = Path(relative)
    if path.is_absolute() or not path.parts or '..' in path.parts:
        raise ValueError(f'Unsafe profile path: {relative}')
    return root / path


def environment():
    home = Path(os.environ['HOME'])
    config = Path(os.environ.get('XDG_CONFIG_HOME') or home / '.config')
    state = Path(os.environ.get('XDG_STATE_HOME') or home / '.local/state')
    if not all(p.is_absolute() for p in (home, config, state)):
        raise ValueError('HOME and XDG directories must be absolute')
    return {'home': home.resolve(), 'config': config.resolve(), 'state': state.resolve()}


def resolve(profile, root=ROOT, roots=None):
    roots = environment() if roots is None else roots
    manifest = json.loads((root / 'config/profiles.json').read_text())
    if manifest['version'] != 1:
        raise ValueError('Unsupported profile manifest version')
    if profile not in manifest['profiles']:
        raise ValueError(f'Unknown profile: {profile}')
    links, requirements, skipped = [], [], []
    destinations = set()
    for name in manifest['profiles'][profile]:
        component = manifest['components'][name]
        mappings = list(component.get('links', []))
        if 'skills' in component:
            source = inside(root, component['skills'])
            if not source.is_dir():
                raise ValueError(f'Missing required source: {source}')
            consumers = ['.agents'] + [h for h in HARNESSES if (roots['home'] / h).is_dir()]
            for skill in sorted(source.iterdir()):
                if skill.is_dir() and (skill / 'SKILL.md').is_file():
                    mappings.extend((str(skill.relative_to(root)), 'home', f'{h}/skills/{skill.name}')
                                    for h in consumers)
        for relative, location, target in mappings:
            source = inside(root, relative)
            if not source.exists():
                if component.get('optional_source'):
                    skipped.append({'component': name, 'source': relative, 'reason': 'not published'})
                    continue
                raise ValueError(f'Missing required source: {relative}')
            if not source.resolve().is_relative_to(root.resolve()):
                raise ValueError(f'Source escapes checkout: {relative}')
            if location not in ('home', 'config'):
                raise ValueError(f'Unknown target root: {location}')
            destination = inside(roots[location], target)
            if str(destination) in destinations:
                raise ValueError(f'Duplicate target: {destination}')
            destinations.add(str(destination))
            links.append({'component': name, 'source': str(source), 'target': str(destination)})
        for kind in ('required', 'optional'):
            for requirement in component.get(kind, []):
                requirements.append({**requirement, 'component': name, 'required': kind == 'required',
                                     'executable': shutil.which(requirement['command']),
                                     'version_checked': False})
    return {'version': 1, 'profile': profile, 'root': str(root), 'links': links,
            'requirements': requirements, 'skipped': skipped}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('profile', choices=('headless', 'desktop', 'bin', 'rex'))
    args = parser.parse_args()
    print(json.dumps(resolve(args.profile), indent=2))


if __name__ == '__main__':
    try:
        main()
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f'Profile error: {error}', file=sys.stderr)
        sys.exit(1)
