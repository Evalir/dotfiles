#!/usr/bin/env bash
#
# devenv.sh — the fuller dev environment, without Nix.
#
# This is the portable equivalent of normandy's `home.packages`: core CLI, language
# toolchains, and the native build deps that cargo/npm need to compile C. normandy gets
# these from home-manager, which only works on a box running Nix; everything here comes
# from the system package manager (or the tool's own installer where the distro version
# is unusable), so it works on macOS, Debian/Ubuntu, Fedora, and Arch alike.
#
# Deliberately NOT included: the k3s tooling (kubectl/helm/k9s/kubeseal) and nmtop, which
# only make sense on a box running that cluster.
#
# Usage:
#   bash install/devenv.sh            # everything
#   bash install/devenv.sh cli        # core CLI only
#   bash install/devenv.sh lang build # subsets, space separated
#
# Self-contained — depends on nothing else in this repo, so it can be curl'd onto a box
# that has no checkout yet. Safe to re-run: anything already on PATH is skipped, so it
# never fights an existing install (distro, brew, cargo install, or hand-built).
#
# A package the distro doesn't carry (eza on old Debian, zellij on any Debian) is reported
# at the end rather than aborting the run — one gap shouldn't cost you the other 20 tools.

set -uo pipefail # NOT -e: individual failures are collected and reported, not fatal

# ── groups ────────────────────────────────────────────────────────────────────
# Canonical tool names. The binary to test for differs from the package name often enough
# that `ensure` takes both.
#
#   cli    ripgrep fd fzf jq bat eza tree htop git-lfs   (loops over CLI_TOOLS below)
#   lang   rustup node go python3                        (rustup is special-cased)
#   build  gcc make pkg-config                           (macOS gets these from Xcode CLT)
#
# Only the CLI group is a plain list; the other two need per-tool handling, so they're
# spelled out in their sections rather than driven from an array.
CLI_TOOLS=(ripgrep fd fzf jq bat eza tree htop git-lfs)

want_cli=0 want_lang=0 want_build=0
if [ "$#" -eq 0 ]; then
    want_cli=1 want_lang=1 want_build=1
else
    for g in "$@"; do
        case "$g" in
            cli) want_cli=1 ;;
            lang) want_lang=1 ;;
            build) want_build=1 ;;
            all) want_cli=1 want_lang=1 want_build=1 ;;
            -h | --help)
                sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
                exit 0
                ;;
            *)
                echo "unknown group: $g (want: cli, lang, build, all)" >&2
                exit 2
                ;;
        esac
    done
fi

have() { command -v "$1" >/dev/null 2>&1; }

# Root doesn't need sudo; otherwise use it if present.
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif have sudo; then
    SUDO="sudo"
else
    SUDO=""
fi

# ── package manager ───────────────────────────────────────────────────────────
if have brew; then
    MGR=brew
elif have apt-get; then
    MGR=apt
elif have dnf; then
    MGR=dnf
elif have pacman; then
    MGR=pacman
else
    echo "No supported package manager found (brew/apt/dnf/pacman)." >&2
    exit 1
fi

echo "Package manager: $MGR"
echo

failed=()
installed=()
skipped=()

install_pkgs() {
    case "$MGR" in
        brew) brew install "$@" ;;
        apt) $SUDO apt-get install -y "$@" ;;
        dnf) $SUDO dnf install -y "$@" ;;
        pacman) $SUDO pacman -S --needed --noconfirm "$@" ;;
    esac
}

# Canonical tool -> the package(s) that provide it on this manager.
#
# The mapping exists because names genuinely diverge: Debian ships fd as `fd-find` and Go
# as `golang-go`; Fedora calls pkg-config `pkgconf-pkg-config`; Arch folds the whole
# toolchain into `base-devel`; Debian splits venv/pip/headers out of `python3`. Printing
# "not packaged" for an empty result is deliberate — it separates "the distro doesn't have
# this" from "the install failed".
pkgs_for() {
    case "$MGR:$1" in
        # fd and bat collide with existing Debian binaries, so Debian renames the
        # BINARIES (fdfind / batcat). Shimmed back to the real names below.
        apt:fd) echo fd-find ;;
        dnf:fd) echo fd-find ;;
        *:fd) echo fd ;;

        apt:go) echo golang-go ;;
        dnf:go) echo golang ;;
        brew:go) echo go ;;
        pacman:go) echo go ;;

        apt:node) echo "nodejs npm" ;;
        dnf:node) echo "nodejs npm" ;;
        brew:node) echo node ;;
        pacman:node) echo "nodejs npm" ;;

        # Debian splits venv, pip, and the C headers out of the interpreter package;
        # without them `python3 -m venv` and any C-extension build fail confusingly.
        apt:python3) echo "python3 python3-venv python3-pip python3-dev" ;;
        dnf:python3) echo "python3 python3-pip python3-devel" ;;
        brew:python3) echo python3 ;;
        pacman:python3) echo python ;;

        # On macOS the compiler and make come from the Xcode Command Line Tools, not brew.
        brew:gcc | brew:make) echo "" ;;
        apt:gcc | apt:make) echo build-essential ;;
        dnf:gcc) echo "gcc gcc-c++" ;;
        dnf:make) echo make ;;
        pacman:gcc | pacman:make) echo base-devel ;;

        apt:pkg-config) echo pkg-config ;;
        dnf:pkg-config) echo pkgconf-pkg-config ;;
        brew:pkg-config) echo pkg-config ;;
        pacman:pkg-config) echo pkgconf ;;

        # Everything else uses the same name everywhere.
        *:ripgrep) echo ripgrep ;;
        *:fzf) echo fzf ;;
        *:jq) echo jq ;;
        *:bat) echo bat ;;
        *:eza) echo eza ;;
        *:tree) echo tree ;;
        *:htop) echo htop ;;
        *:git-lfs) echo git-lfs ;;
        *) echo "" ;;
    esac
}

# ensure <canonical> [binary-to-test...]
#
# Extra args are candidate binary names, tried in order. That matters for fd and bat,
# which Debian ships as `fdfind` and `batcat` — without checking both names, a re-run
# would reinstall a package that's already there.
ensure() {
    local tool="$1"
    shift
    local bins=("$@")
    [ "${#bins[@]}" -eq 0 ] && bins=("$tool")

    # Test for the BINARY, not the package: a tool already present via cargo install,
    # brew, or a hand-built copy should not be reinstalled from the distro.
    local b
    for b in "${bins[@]}"; do
        if have "$b"; then
            skipped+=("$tool")
            printf '  ok        %-12s (%s)\n' "$tool" "$(command -v "$b")"
            return
        fi
    done

    local pkgs
    pkgs="$(pkgs_for "$tool")"
    if [ -z "$pkgs" ]; then
        printf '  SKIP      %-12s no package on %s\n' "$tool" "$MGR"
        failed+=("$tool (not packaged for $MGR)")
        return
    fi

    printf '  install   %-12s -> %s\n' "$tool" "$pkgs"
    # shellcheck disable=SC2086  # word splitting is intended: pkgs may be a list
    if install_pkgs $pkgs >/dev/null 2>&1; then
        installed+=("$tool")
    else
        failed+=("$tool ($pkgs)")
        printf '            !! failed\n'
    fi
}

# ── refresh indexes once up front ─────────────────────────────────────────────
case "$MGR" in
    apt) echo "Refreshing package index…"; $SUDO apt-get update -qq ;;
    pacman) $SUDO pacman -Sy --noconfirm >/dev/null 2>&1 ;;
esac

# ── native build deps ─────────────────────────────────────────────────────────
# First, because the language toolchains want a working compiler.
if [ "$want_build" -eq 1 ]; then
    echo
    echo "native build deps"
    if [ "$MGR" = brew ]; then
        # gcc/clang and make ship with the Command Line Tools. Installing them is an
        # interactive GUI flow, so advise rather than pretend to do it.
        if xcode-select -p >/dev/null 2>&1; then
            printf '  ok        %-12s (Xcode Command Line Tools)\n' "cc/make"
        else
            printf '  SKIP      %-12s run: xcode-select --install\n' "cc/make"
            failed+=("Xcode Command Line Tools (run: xcode-select --install)")
        fi
        ensure pkg-config pkg-config
    else
        ensure gcc gcc
        ensure make make
        ensure pkg-config pkg-config
    fi
fi

# ── core CLI ──────────────────────────────────────────────────────────────────
if [ "$want_cli" -eq 1 ]; then
    echo
    echo "core CLI"
    for t in "${CLI_TOOLS[@]}"; do
        case "$t" in
            # Debian renames these binaries, so accept either name as "already present".
            fd) ensure fd fd fdfind ;;
            bat) ensure bat bat batcat ;;
            # The binary is `rg`, not `ripgrep`.
            ripgrep) ensure ripgrep rg ;;
            *) ensure "$t" "$t" ;;
        esac
    done

    # Shim the Debian-renamed binaries back to their real names. ~/.local/bin keeps this
    # a per-user change with no sudo and nothing for the package manager to collide with.
    mkdir -p "$HOME/.local/bin"
    for pair in "fdfind:fd" "batcat:bat"; do
        real="${pair%%:*}" want="${pair##*:}"
        have "$want" && continue # real name already resolves; nothing to shim
        have "$real" || continue # renamed binary isn't here either
        target="$(command -v "$real")"
        link="$HOME/.local/bin/$want"
        # Report an existing correct shim as `ok` rather than re-announcing it: this runs
        # from shells where ~/.local/bin isn't on PATH, so `have $want` above can't be the
        # thing that detects it.
        if [ -L "$link" ] && [ "$(readlink "$link")" = "$target" ]; then
            printf '  ok        %-12s (shim -> %s)\n' "$want" "$target"
        else
            ln -sf "$target" "$link"
            printf '  shim      %-12s -> %s\n' "$want" "$target"
        fi
    done

    # git-lfs needs a one-time hook install per user; idempotent.
    if have git-lfs; then git lfs install >/dev/null 2>&1 || true; fi
fi

# ── language toolchains ───────────────────────────────────────────────────────
if [ "$want_lang" -eq 1 ]; then
    echo
    echo "language toolchains"

    # rustup comes from rustup.rs on EVERY platform, not the package manager. Distro
    # rustup packages are frequently stale or wired to a distro-managed toolchain, which
    # then fights `rustup update`. The official installer is the same everywhere and puts
    # toolchains in ~/.rustup with shims in ~/.cargo/bin.
    # Check the install location directly as well as $PATH: a non-interactive shell
    # (`ssh box ./devenv.sh`) has no ~/.cargo/bin, so a PATH-only test would report rustup
    # missing on a box that has it and pointlessly re-run the installer.
    if have rustup || have cargo || [ -x "$HOME/.cargo/bin/rustup" ]; then
        printf '  ok        %-12s (%s)\n' rustup \
            "$(command -v rustup || command -v cargo || echo "$HOME/.cargo/bin/rustup")"
        skipped+=(rustup)
    elif have curl; then
        printf '  install   %-12s -> rustup.rs (official installer)\n' rustup
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1; then
            installed+=(rustup)
        else
            failed+=("rustup (rustup.rs installer)")
            printf '            !! failed\n'
        fi
    else
        failed+=("rustup (needs curl)")
    fi

    ensure node node
    ensure go go
    ensure python3 python3
fi

# ── report ────────────────────────────────────────────────────────────────────
echo
echo "──────────────────────────────────────────────────────────────"
printf 'installed: %s\n' "${installed[*]:-none}"
printf 'already present: %s\n' "${skipped[*]:-none}"

if [ "${#failed[@]}" -gt 0 ]; then
    echo
    echo "needs attention:"
    for f in "${failed[@]}"; do echo "  - $f"; done
fi

# Versions, resolved through a PATH that includes the two dirs a fresh shell may not have
# picked up yet (~/.cargo/bin from rustup, ~/.local/bin for the shims).
echo
echo "versions (PATH includes ~/.cargo/bin and ~/.local/bin):"
export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
for probe in "rg --version" "fd --version" "fzf --version" "jq --version" \
    "bat --version" "eza --version" "tree --version" "htop --version" \
    "git-lfs --version" "rustc --version" "cargo --version" "node --version" \
    "go version" "python3 --version" "gcc --version" "make --version" \
    "pkg-config --version"; do
    bin="${probe%% *}"
    if have "$bin"; then
        printf '  %-10s %s\n' "$bin" "$($probe 2>&1 | head -1)"
    else
        printf '  %-10s —\n' "$bin"
    fi
done

echo
echo "New shims/toolchains land in ~/.local/bin and ~/.cargo/bin — open a new shell (the"
echo "fish config in this repo adds both) or: set -gx PATH ~/.cargo/bin ~/.local/bin \$PATH"

# Exit non-zero only if something genuinely failed, so CI/automation can gate on it.
[ "${#failed[@]}" -eq 0 ]
