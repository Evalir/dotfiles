# evalir's personal fish config — dropped in additively via conf.d.
#
# Everything in ~/.config/fish/conf.d/*.fish is auto-sourced by fish on every
# startup, BEFORE config.fish, for both interactive and non-interactive shells.
# That means this layers on top of whatever config.fish a machine already has
# without overwriting it. Keep it portable and guard anything machine-specific.

# Load the shared function/alias bundle (ls, ll, ship, glog, nv, normandy, ...).
# These live in one file, so fish's per-file autoload won't pick them up on its
# own — source it explicitly.
if test -f $__fish_config_dir/functions/evalir.fish
    source $__fish_config_dir/functions/evalir.fish
end

# Dev toolchains on PATH. fish_add_path is idempotent and harmless if the dir
# doesn't exist yet, so this is safe to run on any box.
# ~/.local/bin: the curl-installed `claude`, pipx/uv shims, and the fd/bat name shims
# devenv.sh drops there on Debian (where the packages are fdfind/batcat).
fish_add_path ~/.local/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.zvm/bin
fish_add_path ~/.zvm/self
fish_add_path ~/.bun/bin
fish_add_path ~/.sp1/bin
fish_add_path ~/.bifrost/bin
set -gx ZIG_INSTALL ~/.zvm/self

# Forwarded ssh agent + long-lived tmux sessions.
#
# On a box that deliberately holds no private key (git authenticates through the agent
# forwarded from the laptop), every reconnect gets a NEW socket path like
# /tmp/auth-agentXXXX/listener.sock. A tmux session created under an earlier connection
# keeps the old path in its environment, so after reattaching, git fails with an
# unreachable agent. Fix: keep one stable path, repoint it on each fresh login, and have
# shells use it — sessions inside tmux then follow the live socket automatically.
#
# Guarded on SSH_CONNECTION so a local machine's own agent (1Password et al.) is untouched.
if set -q SSH_CONNECTION
    set -l stable $HOME/.ssh/agent.sock

    # A real forwarded socket (not our own symlink) -> repoint the stable path at it.
    if set -q SSH_AUTH_SOCK; and test "$SSH_AUTH_SOCK" != "$stable"; and test -S "$SSH_AUTH_SOCK"
        mkdir -p $HOME/.ssh
        ln -sf "$SSH_AUTH_SOCK" "$stable"
    end

    # `test -S` follows the link, so a stale one (dead target) fails here and is ignored.
    if test -S "$stable"
        set -gx SSH_AUTH_SOCK "$stable"
    end
end

# Prompt — only if starship is actually installed on this box.
if status is-interactive
    if type -q starship
        starship init fish | source
    end
end
