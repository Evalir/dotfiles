# Full setup on a fresh box: install prerequisites, then symlink configs
setup: bootstrap link

# Install prerequisites; auto-detects brew/apt/dnf/pacman. Re-runnable
bootstrap:
    bash ./install/bootstrap.sh

# Symlink configs into ~/.config, backing up whatever is there. Re-runnable
link:
    bash ./install/link.sh

# Update the usual toolchains
gm:
    rustup update
    rustup update nightly
    foundryup
