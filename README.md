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

`link` symlinks the tracked configs into place (mostly `~/.config`):

- **command launchers** — `shell/bin/torvus` -> `~/.local/bin/torvus`.
  Use `just link-bin` to install only launchers. The fish config adds
  `~/.local/bin` to PATH; other shells must include it too.
- **fish** is layered in *additively* — `conf.d/evalir.fish` (personal
  config: PATHs, prompt, sources the function bundle) and
  `functions/evalir.fish`. Your machine's own `config.fish` is never touched.
- **tmux** — `shell/tmux/tmux.conf` -> `~/.config/tmux/tmux.conf` (XDG path,
  tmux >= 3.1).
- **nvim** is symlinked as a whole dir (`editors/nvim` -> `~/.config/nvim`).
  Requires Neovim 0.12+ and tree-sitter CLI 0.26.1+; see the
  [Neovim guide](editors/nvim/README.md) for setup and shortcuts.
- **agent skills** — `agents/skills` -> `~/.agents/skills` (the canonical,
  harness-neutral copy), and each skill linked into `~/.cursor/skills`,
  `~/.claude/skills` and `~/.codex/skills` for whichever of those is installed.
  Edit in the repo; every harness sees it. For a repo that cloud agents work
  in, `bash install/agent-skills.sh <checkout>` vendors them into its
  `.claude/skills/` as tracked project skills instead — a cloud sandbox clones
  the repo and never sees this home directory.

Anything already at a target path is moved aside to a timestamped
`*.bak.<date>` before linking, so nothing is clobbered. It's safe to re-run:
targets already pointing at the repo are left alone. Because it's symlinks, a
later `git pull` updates every linked machine.

## Dev environment (without Nix)

`just devenv` installs the fuller toolset — the portable equivalent of what
[normandy](https://github.com/Pendrana-Systems/Normandy)'s home-manager config
provides, for boxes that don't run Nix:

| group | tools |
|---|---|
| `cli` | ripgrep · fd · fzf · jq · bat · eza · tree · htop · git-lfs |
| `lang` | rustup · node · go · python3 |
| `build` | gcc · make · pkg-config |

```sh
just devenv                # everything
just devenv cli            # one group
just devenv "lang build"   # several
```

Same conventions as `bootstrap`: auto-detects brew / apt / dnf / pacman,
skips anything already on PATH (so a `cargo install`ed or hand-built copy is
never clobbered), and reports unavailable packages at the end instead of
aborting. It ends with a version table so you can see what actually landed.

Two things it handles that bite otherwise:

- **rustup always comes from rustup.rs**, never the package manager — distro
  rustup packages are often stale or bound to a distro-managed toolchain that
  then fights `rustup update`.
- **Debian renames `fd` and `bat`** to `fdfind` and `batcat` (binary name
  collisions). The script symlinks them back to the real names in
  `~/.local/bin`, which `conf.d/evalir.fish` puts on `$PATH`.

The k3s tooling (kubectl/helm/k9s/kubeseal) and `nmtop` are deliberately left
out — those only make sense on the box running that cluster.

## Durable remote sessions

Headless boxes run long jobs and Claude Code inside a multiplexer, so work
survives a dropped connection. The fish bundle carries the helpers:

| command | what |
|---|---|
| `s [name]`  | attach or create a **tmux** session (default `main`) |
| `s -k [name]` | kill a work group + everything in it; no name → fzf picker |
| `zj [name]` | attach or create a **zellij** session (default `main`, only if zellij is installed) |
| `sls`       | list active tmux + zellij sessions |
| `normandy` / `nmd` | mosh to the Asahi box; `normandy <session>` lands straight in `s <session>` |
| `swanbots` / `swb` | same, for the Debian GPU box |
| `torvus` | Mosh to Torvus with immediate local typing prediction |
| `torvus --safe` | ordinary SSH to Torvus for hidden passwords/tokens |

`s` uses tmux **session groups**: the windows/panes are shared, but each client
attaches through its own throwaway session, so window selection and size stay
independent across your laptop and phone.

The `swanbots` helper doesn't specify a login user — set `User` for that host in
`~/.ssh/config` if it differs from your local username.

### Torvus on another machine

With this repo cloned, Mosh installed, and `ssh torvus` working:

```sh
cd ~/dotfiles
just link-bin             # or: bash install/link.sh --bin
torvus                    # immediate local typing via Mosh
torvus --safe             # ordinary SSH
```

Full `just setup` installs Mosh and links the launcher too. The launcher works
on macOS and Linux; its symlink follows future `git pull` updates. Existing
launchers are backed up, and rerunning the installer leaves correct links alone.

SSH credentials and agent settings remain machine-specific. For a new machine,
configure the `Host torvus` alias for `evalir@37.27.118.27` using your authorized
SSH key/agent. The [Torvus SSH reference](https://github.com/Pendrana-Systems/torvus/blob/main/mac-ssh.conf)
shows the Mac/1Password setup; [keys/login.pub](https://github.com/Pendrana-Systems/torvus/blob/main/keys/login.pub)
is the public identity selector. Configure the agent socket for your OS rather
than copying a private key into this repo.

The default uses `mosh --predict=experimental`: typing appears locally before
the server confirms it. It can briefly show characters even at hidden-input
prompts, so use `torvus --safe` for passwords/tokens. A reminder is printed on
each normal connection. Command output and completion still wait on the network.
`ssh torvus` and other Mosh connections are unchanged; `torvus --help` shows usage.

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
