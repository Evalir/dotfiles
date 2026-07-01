# Full setup on a fresh box: install prerequisites, then symlink configs.
setup: bootstrap link

# Install prerequisite packages (neovim, mosh, eza, starship). Assumes the
# basics (fish, git, curl, tmux). Auto-detects brew/apt/dnf/pacman. Re-runnable.
bootstrap:
    bash ./install/bootstrap.sh

# Non-destructive install: symlink configs into place, backing up anything
# that already exists. Fish is layered in additively (conf.d + functions), so
# an existing config.fish is left untouched. Safe to re-run.
link:
    bash ./install/link.sh

# Install everything (destructive copy — overwrites ~/.config/nvim & fish)
install-all: fishrc nvim

# Install the `.fishrc` config
fishrc:
    cp ./shell/fish/ ~/.config/fish/

# Install the custom nvim conf
nvim:
    rm -rf ~/.config/nvim
    cp -R ./editors/nvim ~/.config/nvim

# Sync the current configs
senv:
    rm -rf ./editors/nvim
    rm -rf ./shell/fish/config.fish
    rm -rf ./shell/fish/functions/evalir.fish
    cp -R ~/.config/nvim ./editors/nvim
    cp ~/.config/fish/config.fish ./shell/fish/config.fish
    cp ~/.config/fish/functions/evalir.fish ./shell/fish/functions/evalir.fish
    rm -rf ./editors/nvim/.git
    rm -rf ./editors/nvim/.github
    rm -rf ./editors/nvim/doc

# update usual programs
gm:
    rustup update
    rustup update nightly
    foundryup
