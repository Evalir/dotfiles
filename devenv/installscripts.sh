#! /usr/bin/env bash
# If you're installing this from  a new computer, remember to make it executable
# chmod u+x installscripts

# --- GENERAL DEV TOOLS ---
# homebrew install
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap caskroom/cask
# xcode dev tools
xcode-select --install
# install git
brew install git
# install iterm2
brew cask install iterm2
# install firefox
brew cask install firefox
# install brave
brew cask install brave-browser
# install neovim
brew install neovim
# install vim plug for neovim
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
# install zsh
brew install zsh
# install vscode
brew cask install visual-studio-code 
# --- PROGRAMMING ---
# install node
brew install node
brew install yarn
brew install nvm
# install python
brew install python
pip install --user pipenv
pip install virtualenv
# install solidity (js)
npm install -g solc
# -- blockchain stuff --
npm install -g truffle
# upgrade ruby
brew upgrade ruby
# install go
# NOTE: Go needs more setup, as exporting the gopath & more devtools.
brew install go
# install rust
brew install rustup
rustup-init

# utilities
# heroku
brew install heroku/brew/heroku
heroku upgrade
# tree
brew install tree
# fzf
brew install fzf
# upgrade all
brew update && brew upgrade && brew cleanup && brew doctor
