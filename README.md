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
just bootstrap     # install neovim, mosh, eza, starship (assumes fish/git/curl/tmux)
just link          # symlink configs into ~/.config
```

`bootstrap` auto-detects the package manager (brew / apt / dnf / pacman) and
installs prerequisites; a package that isn't available (e.g. `eza` on older
Debian) is reported rather than aborting the run.

`link` symlinks the tracked configs into `~/.config`:

- **fish** is layered in *additively* — `conf.d/evalir.fish` (personal
  config: PATHs, prompt, sources the function bundle) and
  `functions/evalir.fish`. Your machine's own `config.fish` is never touched.
- **nvim** is symlinked as a whole dir (`editors/nvim` -> `~/.config/nvim`).

Anything already at a target path is moved aside to a timestamped
`*.bak.<date>` before linking, so nothing is clobbered. It's safe to re-run:
targets already pointing at the repo are left alone. Because it's symlinks, a
later `git pull` updates every linked machine.

## Making changes

Edit the files in this repo directly — on a linked machine that *is* the live
config. Commit and push, then `git pull` on the other boxes.

If a machine was set up by hand and isn't linked yet, run `just link`: the
existing config is backed up to `*.bak.<date>` first, so you can pull anything
worth keeping out of the backup and into the repo before deleting it.
