#!/usr/bin/env bash
# Portable profile linker. --bin and --rex retain their scoped mappings.
# Preview with --dry-run; use --adopt to back up unmanaged target collisions.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "$REPO_ROOT/install/link.py" "$@"
