##############################################################
# To fix ruby GEMS ASCII errors.
##############################################################

export LC_CTYPE="utf-8"

##############################################################
# Path to your oh-my-zsh configuration.
##############################################################

ZSH=$HOME/.oh-my-zsh

##############################################################
# Set name of the theme to load.
##############################################################

ZSH_THEME="gabri-new"

##############################################################
# aliases
##############################################################

alias reload="source ~/.zshrc && rvm reload"
alias zshconfig="subl -a ~/.zshrc"
alias ohmyzsh="subl -a ~/.oh-my-zsh"
alias server="open http://localhost:8000 && python -m SimpleHTTPServer"
alias desk="cd ~/Desktop"
alias dropbox="cd ~/Dropbox"
alias ..="cd ../"
alias ...="cd ../../"
alias "?"="pwd"
alias pu="pushd"
alias po="popd"
alias d="dirs -v"
alias sp="sass --watch --style compressed" # later on we can use --sourcemap
alias sd="sass --watch --debug-info" # later on we can use --sourcemap this makes it work in Chrome ;)

##############################################################
# Functions
##############################################################

# My Startup Template.
function new_template(){
  git clone git@github.com:ahmedelgabri/Startup-template.git $@
}

# WordPress latest
function new_wp() {
  latest="http://wordpress.org/latest.zip"
  curl -O $latest
  unzip latest.zip
  rm -rf __MACOSX latest.zip
  cp -rf ./wordpress/* ./
  rm -rf ./wordpress/
  mkdir ./wp-content/uploads/
  mv wp-config-sample.php wp-config.php
  touch .htaccess
  subl wp-config.php
  open https://api.wordpress.org/secret-key/1.1/salt/
}

# make a directory and cd to it
mcd() {
    test -d "$1" || mkdir "$1" && cd "$1"
}

# vHosts
function vhosts() {
  subl /etc/hosts
  #subl /Applications/MAMP/conf/apache/extra/httpd-vhosts.conf
}

# Git functions
function git_since(){
  git lg --since=$@
}

function git_until(){
  git lg --until=$@
}

function git_author(){
  git lg --author="$@"
}

function git_grep(){
  git lg --grep="$@"
}

##############################################################
# ZSH Configurations.
##############################################################

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git osx brew gem ruby heroku)

source $ZSH/oh-my-zsh.sh

##############################################################
# PATH.
##############################################################

# export PATH=:/usr/local/bin
# export PATH=$PATH:/usr/bin
# export PATH=$PATH:/bin
# export PATH=$PATH:/usr/sbin
# export PATH=$PATH:/sbin
# export PATH=$PATH:/usr/local/Cellar/git
# export PATH=$PATH:/usr/local/share/npm/bin
# export PATH=$PATH:/.rvm/bin

export PATH="/usr/local/bin:/usr/local/sbin:~/bin:$PATH"

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*