#!/usr/bin/env bash
#
# Non-destructive dotfiles installer.
#
# Symlinks the tracked configs into place (works on macOS and Linux). Anything
# already living at a target path is moved aside to a timestamped .bak before the
# symlink is created, so nothing is ever clobbered. Safe to re-run: targets that
# already point at this repo are left untouched.
#
# Usage:  bash install/link.sh          # from anywhere; resolves the repo itself
#
set -euo pipefail

# Repo root = parent of this script's dir, resolved to an absolute path.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STAMP="$(date +%Y%m%d-%H%M%S)"

# src (relative to repo) -> dst (absolute). One pair per line.
#
# Fish is installed additively: personal config lands in conf.d/ (auto-sourced,
# layered on top of any existing config.fish) and the function bundle in
# functions/. The machine's own config.fish is never touched. nvim is a whole
# config, so its dir is symlinked as a unit (existing one is backed up first).
# tmux.conf goes to the XDG path (tmux >= 3.1); on a Nix box, drop
# `programs.tmux` from home-manager first so the two don't fight over it.
MAPPINGS=(
    "shell/fish/conf.d/evalir.fish|$CONFIG_HOME/fish/conf.d/evalir.fish"
    "shell/fish/functions/evalir.fish|$CONFIG_HOME/fish/functions/evalir.fish"
    "shell/tmux/tmux.conf|$CONFIG_HOME/tmux/tmux.conf"
    "editors/nvim|$CONFIG_HOME/nvim"
)

link_one() {
    local src="$REPO_ROOT/$1" dst="$2"

    if [ ! -e "$src" ]; then
        printf '  MISSING  %s (not in repo, skipping)\n' "$1"
        return
    fi

    # Already the correct symlink? Nothing to do — keeps re-runs a no-op.
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        printf '  ok       %s\n' "$dst"
        return
    fi

    mkdir -p "$(dirname "$dst")"

    # Back up whatever is currently there (real file/dir, or a stale symlink).
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        local bak="$dst.bak.$STAMP"
        local n=1
        while [ -e "$bak" ] || [ -L "$bak" ]; do
            bak="$dst.bak.$STAMP.$n"
            n=$((n + 1))
        done
        mv "$dst" "$bak"
        printf '  backup   %s -> %s\n' "$dst" "$bak"
    fi

    ln -s "$src" "$dst"
    printf '  link     %s -> %s\n' "$dst" "$src"
}

echo "Linking dotfiles from $REPO_ROOT"
echo "Config home: $CONFIG_HOME"
echo
for m in "${MAPPINGS[@]}"; do
    link_one "${m%%|*}" "${m#*|}"
done
echo
echo "Done. Backups (if any) are alongside each target as *.bak.$STAMP"
