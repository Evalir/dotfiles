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
fish_add_path ~/.cargo/bin
fish_add_path ~/.zvm/bin
fish_add_path ~/.zvm/self
fish_add_path ~/.bun/bin
fish_add_path ~/.sp1/bin
fish_add_path ~/.bifrost/bin
set -gx ZIG_INSTALL ~/.zvm/self

# Prompt — only if starship is actually installed on this box.
if status is-interactive
    if type -q starship
        starship init fish | source
    end
end
