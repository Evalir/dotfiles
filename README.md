# dotfiles

The only thing they fear is :q!

## Install

Non-destructive, symlink-based. Clone the repo, then:

```sh
git clone git@github.com:Evalir/dotfiles.git ~/dotfiles
cd ~/dotfiles
just setup         # bootstrap (install prereqs) + link
```

Or run the two steps individually:

```sh
just bootstrap     # install neovim, mosh, eza, zellij, starship (assumes fish/git/curl/tmux)
just link          # symlink configs into ~/.config
```

`bootstrap` auto-detects the package manager (brew / apt / dnf / pacman) and
installs prerequisites; a package that isn't available (e.g. `eza` on older
Debian, `zellij` on any Debian) is reported rather than aborting the run.

`link` symlinks the tracked configs into `~/.config`:

- **fish** is layered in *additively* — `conf.d/evalir.fish` (personal
  config: PATHs, prompt, sources the function bundle) and
  `functions/evalir.fish`. Your machine's own `config.fish` is never touched.
- **tmux** — `shell/tmux/tmux.conf` -> `~/.config/tmux/tmux.conf` (XDG path,
  tmux >= 3.1).
- **nvim** is symlinked as a whole dir (`editors/nvim` -> `~/.config/nvim`).

Anything already at a target path is moved aside to a timestamped
`*.bak.<date>` before linking, so nothing is clobbered. It's safe to re-run:
targets already pointing at the repo are left alone. Because it's symlinks, a
later `git pull` updates every linked machine.

## Durable remote sessions

Headless boxes run long jobs and Claude Code inside a multiplexer, so work
survives a dropped connection. The fish bundle carries the helpers:

| command | what |
|---|---|
| `s [name]`  | attach or create a **tmux** session (default `main`) |
| `zj [name]` | attach or create a **zellij** session (default `main`, only if zellij is installed) |
| `sls`       | list active tmux + zellij sessions |
| `normandy` / `nmd` | mosh to the Asahi box; `normandy <session>` lands straight in `s <session>` |
| `swanbots` / `swb` | same, for the Debian GPU box |

`s` uses tmux **session groups**: the windows/panes are shared, but each client
attaches through its own throwaway session, so window selection and size stay
independent across your laptop and phone.

The `swanbots` helper doesn't specify a login user — set `User` for that host in
`~/.ssh/config` if it differs from your local username.

## Nix-managed boxes

These configs are the single source of truth, including on boxes that otherwise
use home-manager. Before linking there, remove the overlapping home-manager
options so the two don't fight over the same paths:

- drop `programs.tmux` (keep `tmux` in `home.packages`) — otherwise home-manager
  and `link.sh` both want `~/.config/tmux/tmux.conf`
- drop any `programs.fish.functions` that this repo now defines

Then `home-manager switch` **first** (so it releases those paths), and `just
link` after.

## Making changes

Edit the files in this repo directly — on a linked machine that *is* the live
config. Commit and push, then `git pull` on the other boxes.

If a machine was set up by hand and isn't linked yet, run `just link`: the
existing config is backed up to `*.bak.<date>` first, so you can pull anything
worth keeping out of the backup and into the repo before deleting it.
