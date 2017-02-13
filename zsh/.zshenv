# vim:ft=zsh:
#
# Defines environment variables.

##############################################################
# General
###############################################################
setopt autoparamslash  # tab completing directory appends a slash
setopt noflowcontrol   # disable start (C-s) and stop (C-q) characters
setopt interactivecomments  # allow comments, even in interactive shells
setopt printexitvalue       # for non-zero exit status
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt CORRECT

# Better spell checking & auto correction prompt
export SPROMPT="zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "

##############################################################
# Custom/Plugins
###############################################################
export GITHUB_USER="ahmedelgabri"
export PROJECTS="$HOME/Sites/dev"
# Make sure all the repos I clone uses my template, not sure if this is a good idea though?
# export GIT_TEMPLATE_DIR=$HOME/.dotfiles/git/git-template

preview-file() {
  local mime="$(file --mime "$1")"
  if [[ "$mime" =~ directory ]]; then
    tree -C "$1"
  elif [[ ! "$mime" =~ binary ]]; then
    highlight -O ansi -l "$1" 2> /dev/null || cat "$1"
  else
    echo "$1 is a binary file"
  fi
}
# export -f preview-file

export FZF_DEFAULT_OPTS='--min-height 30 --height 50% --reverse --tabstop 2 --multi --margin 0,3,3,3'
export FZF_DEFAULT_COMMAND='rg --no-messages --files --hidden --follow --glob "!.git/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'preview-file {} | head -200' --bind '?:toggle-preview'"
export FZF_CTRL_R_OPTS="--sort --preview 'echo {}' --preview-window down:5:hidden --bind '?:toggle-preview' --bind 'ctrl-y:execute(echo -n {2..} | pbcopy)' --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"

export PURE_PROMPT_SYMBOL="ϟ" # λ ▴ ⚡ ϟ
export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"
export HOMEBREW_INSTALL_BADGE="🍕"
export HOMEBREW_NO_ANALYTICS=1
# export HOMEBREW_NO_INSECURE_REDIRECT=1
# export HOMEBREW_CASK_OPTS=--require-sha

##############################################################
# NVM
###############################################################
export NVM_DIR=~/.nvm

##############################################################
# Python
###############################################################
export PYTHONSTARTUP=$HOME/.pyrc.py

# Virtualenvwrapper
export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--no-site-packages'
export PIP_VIRTUALENV_BASE="$HOME/.virtualenvs"
export PIP_RESPECT_VIRTUALENV=true
