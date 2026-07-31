# eza-backed ls, but only when eza is actually installed. bootstrap tolerates a
# missing eza (it isn't packaged on older Debian), and shadowing `ls`
# unconditionally would break it shell-wide on exactly those boxes.
if type -q eza
    function ls
        command eza $argv
    end

    function ll
        command eza -l -b $argv
    end
else
    function ll
        command ls -l $argv
    end
end

# Cleans up a rust project using clippy nightly and all unstable options.
function ferris
    command cargo +nightly clippy --fix --all-features --workspace -Z unstable-options --allow-dirty --allow-staged && cargo +nightly fmt $argv
end

function gorris
    command cargo clippy --fix --all-features --allow-dirty --allow-staged && cargo +nightly fmt $argv
end

function ultraclaude
    command claude --dangerously-skip-permissions $argv
end

function rclip
    command cargo +nightly clippy --fix --all-features --workspace -Z unstable-options --allow-dirty --allow-staged $argv
end

function rfmt
    command cargo +nightly fmt $argv
end

# one-word commit & push
function ship
    command git commit $argv && git push
end

# quick git log with no page
function glog
  command git --no-pager log --oneline -50 --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cI) %C(bold blue)<%an>%Creset' $argv
end

# Fancier git log
function glog1
    command git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
end

# Neovim
function nv
    command nvim $argv
end

function gp
    command git push $argv
end

# ── durable remote sessions ───────────────────────────────────────────────────
# Run claude (or anything) INSIDE a session so it survives disconnects; the
# session's root is a shell, so quitting claude doesn't kill it. These used to
# live in normandy's home-manager config, which meant only that one box had
# them — they're portable fish, so they belong here where every box gets them.
#
#   s [name]    attach or create a tmux session   (default: main)
#   s -k [name] kill a work group + everything in it (no name → fzf picker)
#   zj [name]   attach or create a zellij session (default: main)
#   sls         list active tmux + zellij sessions

function s
    # -k / --kill: tear down an entire work group — the base session AND every throwaway
    # client session grouped with it — so nothing (e.g. a live claude) is left running.
    if contains -- "$argv[1]" -k --kill
        set -e argv[1]
        set -l grps $argv
        if test -z "$grps"
            # No name → pick group(s) from an fzf list; the selection IS the confirmation.
            # fzf is a hard dependency only on this path, so fail with advice rather than
            # a "command not found" on a box that doesn't have it.
            if not type -q fzf
                echo 's -k with no name needs fzf; pass a group name explicitly' >&2
                return 1
            end
            set -l groups (tmux list-sessions -F '#{session_group}' 2>/dev/null | sort -u)
            test -z "$groups"; and echo 'no active sessions' >&2; and return
            set grps (printf '%s\n' $groups | fzf --multi --reverse --height 40% \
                        --prompt 'kill group> ' --header 'TAB mark · ENTER kill · ESC cancel')
            test -z "$grps"; and return # cancelled / nothing chosen
        end
        for g in $grps
            # Every session in the group shares #{session_group} == $g (the base session $g
            # plus its $g-N client sessions). Killing only the base would orphan the clients
            # and their windows, so kill each session whose group matches. Session names can't
            # contain ':', so it's a safe delimiter for splitting group from name.
            set -l killed 0
            for line in (tmux list-sessions -F '#{session_group}:#{session_name}' 2>/dev/null)
                set -l parts (string split -m1 ':' $line)
                if test "$parts[1]" = "$g"
                    tmux kill-session -t "=$parts[2]" 2>/dev/null; and set killed (math $killed + 1)
                end
            end
            if test $killed -gt 0
                echo "killed group '$g' ($killed sessions)"
            else
                echo "no such group: '$g'" >&2
            end
        end
        return
    end

    set -l grp $argv[1]
    test -z "$grp"; and set grp main
    # `grp` is a shared "work group" whose windows/panes persist. Each client attaches via
    # its OWN throwaway session grouped with it (tmux session groups), so window selection
    # and size are INDEPENDENT — navigating or resizing in one ssh session doesn't control
    # the others. The per-client session self-destroys on detach; the group's windows (and
    # whatever's running in them) live on in the base session.
    tmux has-session -t "=$grp" 2>/dev/null; or tmux new-session -ds $grp
    tmux new-session -t $grp \; set-option destroy-unattached on
end

# zellij isn't packaged on Debian, so guard rather than defining a broken `zj`.
if type -q zellij
    function zj
        set -l name $argv[1]
        test -z "$name"; and set name main
        zellij attach --create $name
    end
end

function sls
    echo '── tmux ──'
    tmux ls 2>/dev/null; or echo '  (no tmux sessions)'
    if type -q zellij
        echo '── zellij ──'
        zellij list-sessions 2>/dev/null; or echo '  (no zellij sessions)'
    end
end

# ── hopping between boxes ─────────────────────────────────────────────────────
# mosh into a dev box, optionally straight into a session.
#   <box>              -> plain login shell
#   <box> <session>    -> run `s <session>` on the box
#   <box> -s <session> -> same
function __evalir_box_session
    set -l target $argv[1]
    set -e argv[1]

    if test (count $argv) -eq 0
        command mosh $target
    else
        if test "$argv[1]" = "-s"
            set -e argv[1]
        end
        command mosh $target -- s $argv
    end
end

# The Fedora Asahi box (M2 Air). Login user differs from the local one, so it's explicit.
function normandy
    __evalir_box_session normandy@normandy $argv
end

function nmd
    normandy $argv
end

# The Debian GPU box. No user prefix — set `User` for it in ~/.ssh/config if the
# remote login name isn't the same as the local one.
function swanbots
    __evalir_box_session swanbots $argv
end

function swb
    swanbots $argv
end
