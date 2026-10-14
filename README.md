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
just link          # desktop profile; requires Python 3.9+
just link-headless # portable server profile, without GUI configuration
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
- **agent skills** — individual links under `~/.agents/skills` and each installed
  harness's skills directory. Unrelated skills, `.system` directories, credentials
  and settings stay untouched. Run the linker again after installing a harness.
  Repo-vendored skills remain a separate `install/agent-skills.sh` operation.

## Portable profiles and ownership

The linker requires Python 3.9+ and never installs packages. `config/profiles.json`
declares the shared components once. `headless` activates fish, tmux, Neovim,
portable launchers and personal agent skills. `desktop` adds Rex and any published
shared Ghostty config. Shared Starship config is linked when published; currently
absent optional sources are reported. With no flags, the profile is `desktop`.
`--bin` and `--rex` still select only their respective mappings.

```sh
just preview                         # headless preview, no filesystem changes
bash install/link.sh --profile headless --dry-run --json
bash install/link.sh --profile headless
# Inspect conflicts, then explicitly back them up and adopt them:
bash install/link.sh --profile headless --adopt
```

Existing correct links are adopted without replacement. Conflicting targets require
`--adopt`, which moves them to uniquely named `.bak.*` siblings before linking.
This also safely converts the old whole-directory `~/.agents/skills` symlink to
individual links, without modifying the checkout through that symlink. Unknown
symlinked parent directories are refused. Existing machine `config.fish`, Torvus
`zz-torvus.fish`, signing identity, services and compiler settings are not managed.

The ownership ledger is `$XDG_STATE_HOME/dotfiles/links.json` (default
`~/.local/state/dotfiles/links.json`). It records each target/source, checkout commit
when available and backup locations. A lock serializes writes; pending records let
a rerun recover interrupted link creation. Repeated runs preserve equal links and
ledger contents. No Git fetch/checkout, package manager or credential access occurs.
The commit field is provenance, not a claim that the checkout is clean/applied.

Obsolete links are reported, not deleted. Add `--prune` to remove only links still
pointing to their recorded source. User replacements and backup files are retained.
Changing from desktop to headless does not remove old GUI links without explicit
pruning. Scoped `--bin`/`--rex` pruning never removes other components. Do not
point two different dotfiles checkouts at the same ownership ledger.

Optional host overrides live outside the shared checkout:

- Fish: `$XDG_CONFIG_HOME/fish/evalir.local.fish` (default `~/.config/fish/`).
- tmux: `~/.tmux.local.conf`.
- Neovim: `$XDG_CONFIG_HOME/dotfiles/nvim.lua` (default `~/.config/dotfiles/nvim.lua`).

The installer never creates, replaces or syncs these override files. Neovim loads
its override after shared setup; restart editors/new shells to pick up changes.
Existing tmux sessions are not reloaded or restarted by linking.

Inspect package-neutral requirements separately:

```sh
python3 install/profile.py headless
```

The report distinguishes required/optional binaries, minimum compatible versions
and PATH availability. `version_checked: false` and `readiness_checked: false`
mean linking is not certification of tool versions, plugins or editor readiness.
Host provisioning supplies prerequisites; full sync/health checking follows in the
next layer. No installed-version or overall-health claim is made by this linker.

Checks:

```sh
python3 -m unittest discover -s install/tests -p 'test_*.py'
bash -n install/link.sh
shellcheck -x -S warning install/link.sh
fish -n shell/fish/conf.d/evalir.fish
fish -n shell/fish/functions/evalir.fish
uv run shell/tests/test_torvus_ssh.py
git diff --check
```

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
| `torvus --ssh` | SSH with local shell-line editing; normal SSH input inside programs |
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
torvus --ssh              # local line editing over SSH (requires uv)
torvus --safe             # ordinary SSH
```

Full `just setup` installs Mosh/uv and links the launcher and its helper. The launcher works
on macOS and Linux; its symlink follows future `git pull` updates. Existing
launcher conflicts require --adopt for a backup; rerunning leaves correct links alone.

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

`torvus --ssh` uses [uv](https://docs.astral.sh/uv/getting-started/installation/)
to cache Python and the pinned `prompt-toolkit` dependency on first use. Install
them on another Mac with `brew install mosh uv`, then run `just link-bin`.
The remote needs fish (already installed on Torvus). Its prompt hooks apply only
to this connection; no server configuration is changed.

At the `[local]>` prompt, typing, cursor movement, and session history are local.
Enter sends the command and switches to ordinary SSH input until fish returns
to its prompt. Neovim, coding agents, and password prompts receive normal remote
input. Tab hands the current line to fish for completion; Ctrl-] hands it over
for remote editing. Local editing resumes after that command finishes. Local
history lives only in memory; fish still records executed commands normally.
Inside tmux or another nested shell, input remains remote. Output and remote
completion still incur network latency. The helper passes terminal titles and
OSC status sequences through; Rex icon behavior still depends on Rex.

Verify the helper with `uv run shell/tests/test_torvus_ssh.py`; add `--live` for
PTY checks against Torvus (including a dummy hidden-input prompt and Neovim).

For **Shift+Enter in Codex over Mosh in Rex**, run `just link-rex` (or
`bash install/link.sh --rex`), then `rex config reload`. Full `just link` also
installs this configuration. `shell/rex/init.lua` sends explicit CSI-u
Shift+Enter only in panes whose title starts with `[mosh]`; keep Mosh's default
title prefix enabled. Local and SSH panes retain native key handling. This was
verified with Rex Beta build 1069, Mosh 1.4.0, and Codex 0.162.1. Rex config
changes need another `rex config reload` after pulling updates.

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

If a machine was set up by hand, inspect `bash install/link.sh --dry-run`, then
use `--adopt` to back up existing config to `*.bak.*`. You can recover anything
worth keeping from those backups and commit it to the repo.

### Published dotfiles on another machine

Keep editing, committing and pushing upstream manually. On each machine, preview
`dotfiles adopt --profile headless --dry-run`, then run the same command without
`--dry-run`. Adoption backs up conflicting links and records any missing tools;
it does not install system packages. Use `desktop` on a workstation.

`dotfiles requirements --json` reports the prerequisites. After installing them,
`dotfiles reconcile` repairs links and restores the published editor lock. It does
not fetch. After a manual `git pull --ff-only`, run it again.

`dotfiles sync --dry-run` previews origin/master. `dotfiles sync` fetches once and
applies that exact published SHA; `--revision FULL_SHA` selects an older published
revision. Dirty checkouts, feature branches, local-only commits, foreign links and
running Neovim instances block application. Nothing is stashed or reset. Existing
shells and jobs survive; reopen editors/new shells to load configuration changes.
Linked files change immediately when Git checks them out; activation is not atomic.

`dotfiles status --json` distinguishes checked-out, attempted, applied and previous
revisions. `dotfiles doctor --scope profile --json` also checks editor readiness.
Interrupted or failed applications remain incomplete until a successful reconcile.
`dotfiles rollback` restores the previous successfully applied source and owned
links. Plugin/parser restoration may need network access; rollback does not undo
system packages or remove installed tools. Host overrides and unrelated skills stay
outside shared ownership. Helpers run from a private temporary copy during updates.

A host can opt into one local post-apply command with
`dotfiles register-hook --hook /absolute/program arg1 arg2`. Arguments are passed
directly, without a shell. The registration stays in local state. Shared profile
health and hook health are separate: a failed hook leaves the successfully applied
SHA intact, and `dotfiles retry-hook` retries only the integration. Hooks that check
the profile must use `doctor --scope profile --json` to avoid recursion. Ordinary
`doctor` includes the recorded integration result, but never runs the hook.

### Sync another host

Publish changes through the existing manual edit, commit and push workflow, then:

```sh
dotfiles sync --host torvus --dry-run
dotfiles sync --host torvus
dotfiles status --host torvus --json
dotfiles doctor --host torvus
```

`--host` operates only on the SSH host alias. It does not sync the caller first,
read its registration, or transfer unpublished edits; a dirty laptop is fine.
The remote resolves its published branch once and uses its own selected profile.
For intentional parity, run `dotfiles sync --revision FULL_SHA` separately on each
machine (adding `--host torvus` for the remote). `reconcile --host torvus` repairs
the revision already checked out remotely without fetching.

The host must already expose `~/.local/bin/dotfiles` and have completed
`dotfiles adopt --profile headless`. This transport never bootstraps a host,
forwards an agent, copies HOME, or changes host-key policy. Requests are JSON on
stdin to a fixed entry point. Remote reports retain profile, attempted/applied
revision, missing capabilities and integration health; `--json` includes those
fields directly. A disconnect means the apply outcome is unknown: check remote
status before retrying. Existing jobs are left running; editor apply still asks
you to close Neovim.
