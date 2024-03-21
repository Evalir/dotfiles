# Install everything
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
