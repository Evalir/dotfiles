#### FIG ENV VARIABLES ####
[ -s ~/.fig/shell/pre.sh ] && source ~/.fig/shell/pre.sh
#### END FIG ENV VARIABLES ####
# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
# Path to your oh-my-zsh installation.
export ZSH=/Users/Evalir/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
# ZSH_THEME="robbyrussell"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# Ignore node modules everywhere
# export FZF_DEFAULT_COMMAND='ag --nocolor --ignore node_modules -g ""'
# thefuck
eval $(thefuck --alias)

# ANTIGEN
# Make sure you have this installed before sourcing this zsh.
# Use the cUrl comman; I have no idea how to use brew for this 🤷
source ~/antigen.zsh

antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle 'wfxr/forgit'

antigen apply

# Completion style
zstyle ':completion:*' menu select

# History
HISTFILE="${ZDOTDIR:-$HOME}/.zhistory"
HISTSIZE=10000
SAVEHIST=10000
setopt AUTO_CD
setopt BANG_HIST
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY
setopt HIST_BEEP

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  zsh-syntax-highlighting
  zsh-autosuggestions
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
alias ara="cd ~/Dev/Work/Aragon"
alias pkn="cd ~/Dev/Work/Pocket"
alias dog="cat"
alias dotfiles="cd ~/Dev/dotfiles && v"
alias gclone="git clone"
alias gp="echo 'gp2 engine!';git push"
alias gpu="echo'🎉';git push -u"
alias gt="git"
alias glog="git --no-pager log --oneline -20"
alias gpl="git fetch && git pull"
alias gti="echo '🚗  vroom vroom';git"
alias gts="echo '🔬🔬';git status"
alias hive="cd ~/Dev/Work/Hive"
alias nv="nvim"
alias nvc="nvim ~/.config/nvim/init.vim"
alias order66="echo 'hablamo nunca 🔪';killall node"
alias psuh="push"
alias tax="tmux attach"
alias tcf="nvim ~/.tmux.conf"
alias v="nvim"
alias vi="nvim"
alias vim="nvim"
alias yolo="echo 'banda de camion 🚛';git push -f"
alias zsc="nvim ~/.zshrc"
alias magic='f() {branch=$(git rev-parse --abbrev-ref HEAD); git commit -m "$1" && git push -u origin $branch;};f'
alias sambil="sam build"
# update dotfiles repo from actual nvim config
alias dotup="echo 'updating dotfiles...';rm -rf ~/dotfiles/nvim && cp -R  ~/.config/nvim ~/dotfiles/nvim && rm -rf ~/dotfiles/nvim/autoload ~/dotfiles/nvim/colors ~/dotfiles/nvim/plugin"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH="$PATH":"$GOPATH"/bin
export DEFAULT_USER="$(whoami)"
export TERM=xterm-256color
export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
export NVM_DIR="$HOME/.nvm"
# avdmanager, sdkmanager
export PATH=$PATH:$ANDROID_SDK_ROOT/tools/bin

# adb, logcat
export PATH=$PATH:$ANDROID_SDK_ROOT/platform-tools

# emulator
export PATH=$PATH:$ANDROID_SDK_ROOT/emulator

[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(starship init zsh)"

#### FIG ENV VARIABLES ####
[ -s ~/.fig/fig.sh ] && source ~/.fig/fig.sh
#### END FIG ENV VARIABLES ####

# Blockchain helpers
source "~/dotfiles/zsh/blockchain.sh"
