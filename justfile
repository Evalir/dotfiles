# Full setup on a fresh box: install prerequisites, then symlink configs
setup: bootstrap link

# Install prerequisites; auto-detects brew/apt/dnf/pacman. Re-runnable
bootstrap:
    bash ./install/bootstrap.sh

# Symlink configs into ~/.config, backing up whatever is there. Re-runnable
link:
    bash ./install/link.sh

# Portable server profile, without GUI configuration or package installation.
link-headless:
    bash ./install/link.sh --profile headless

# Preview changes without touching the home or ownership state.
preview profile="headless":
    bash ./install/link.sh --profile {{ profile }} --dry-run

# Install only command launchers into ~/.local/bin, with backups. Re-runnable
link-bin:
    bash ./install/link.sh --bin

# Install only Rex terminal configuration, with backups. Re-runnable
link-rex:
    bash ./install/link.sh --rex

# Fuller dev environment without Nix: core CLI, language toolchains, native build deps.
# Optionally scope it: `just devenv cli`, `just devenv "lang build"`. Re-runnable
devenv groups="":
    bash ./install/devenv.sh {{ groups }}

# Update the usual toolchains
gm:
    rustup update
    rustup update nightly
    foundryup
