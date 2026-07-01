#!/usr/bin/env bash
#
# Install the packages the dotfiles assume exist, then you can run link.sh.
#
# Detects the system package manager (brew / apt / dnf / pacman) so it works on
# macOS or a fresh Linux box. Packages are installed one at a time and failures
# are collected rather than aborting the run, so e.g. `eza` missing from an old
# Debian won't stop fish/neovim from installing. Safe to re-run: already-present
# packages are a no-op.
#
# Usage:  bash install/bootstrap.sh
#
set -euo pipefail

# Core deps referenced by the fish config and the tmux `s` workflow.
# (fish itself is assumed to be installed already; rust/cargo, bun, zvm are
# heavier dev toolchains — install those yourself.)
PKGS=(neovim tmux mosh eza git curl)

# Root doesn't need sudo; otherwise use it if present.
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

# Resolve package manager -> the command that installs a single package.
install_one() {
    local pkg="$1"
    case "$MGR" in
        brew)   brew install "$pkg" ;;
        apt)    $SUDO apt-get install -y "$pkg" ;;
        dnf)    $SUDO dnf install -y "$pkg" ;;
        pacman) $SUDO pacman -S --needed --noconfirm "$pkg" ;;
    esac
}

if command -v brew >/dev/null 2>&1; then
    MGR=brew
elif command -v apt-get >/dev/null 2>&1; then
    MGR=apt
elif command -v dnf >/dev/null 2>&1; then
    MGR=dnf
elif command -v pacman >/dev/null 2>&1; then
    MGR=pacman
else
    echo "No supported package manager found (brew/apt/dnf/pacman)." >&2
    echo "Install these manually: ${PKGS[*]}" >&2
    exit 1
fi

echo "Package manager: $MGR"

# Refresh indexes once up front where that's a separate step.
case "$MGR" in
    apt)    $SUDO apt-get update ;;
    pacman) $SUDO pacman -Sy ;;
esac

failed=()
for pkg in "${PKGS[@]}"; do
    echo "==> $pkg"
    if ! install_one "$pkg"; then
        echo "    !! failed to install $pkg" >&2
        failed+=("$pkg")
    fi
done

# starship isn't reliably packaged everywhere; use the official installer if the
# package manager didn't already provide it.
if ! command -v starship >/dev/null 2>&1; then
    echo "==> starship (via official installer)"
    if command -v curl >/dev/null 2>&1; then
        curl -sS https://starship.rs/install/install.sh | $SUDO sh -s -- -y \
            || failed+=("starship")
    else
        failed+=("starship")
    fi
fi

echo
if [ "${#failed[@]}" -eq 0 ]; then
    echo "All prerequisites installed. Next: just link  (or bash install/link.sh)"
else
    echo "Done, but these need attention: ${failed[*]}" >&2
    echo "(e.g. eza needs a newer distro or a manual repo on older Debian/Ubuntu.)" >&2
fi
