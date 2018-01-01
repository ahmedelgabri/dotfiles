# vim:ft=zsh:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# zPlugin
##############################################################

if [[ ! -f ~/.zplugin/bin/zplugin.zsh ]]; then
  if (( $+commands[git] )); then
    git clone https://github.com/zdharma/zplugin.git ~/.zplugin/bin
  else
    echo 'git not found' >&2
    exit 1
  fi
fi

source ~/.zplugin/bin/zplugin.zsh
autoload -Uz compinit && compinit -i

NVM_NO_USE=true
zplugin load "lukechilds/zsh-nvm"
zplugin ice pick"async.zsh" src"pure.zsh"; zplugin load "ahmedelgabri/pure"
zplugin ice "knu/z" pick"z.sh"; zplugin load "knu/z"
zplugin load "lukechilds/zsh-better-npm-completion"
zplugin load "molovo/tipz"
zplugin load "zsh-users/zsh-autosuggestions"
zplugin load "zdharma/fast-syntax-highlighting"
zplugin load "zsh-users/zsh-history-substring-search"
# bind UP and DOWN keys
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# bind UP and DOWN arrow keys (compatibility fallback)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Must be the last?
zplugin load "zsh-users/zsh-completions"

ZSH_AUTOSUGGEST_USE_ASYNC=true
TIPZ_TEXT='Alias tip:'

##############################################################
# CONFIG.
##############################################################

for func (~/.dotfiles/zsh/zshrc.d/functions/*.zsh) source $func

##############################################################
# TOOLS.
##############################################################

(( $+commands[grc] )) && source "`brew --prefix`/etc/grc.bashrc"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##############################################################
# direnv.
##############################################################

if [ $(command -v direnv) ]; then
  export NODE_VERSIONS="$HOME/.nvm/versions/node"
  export NODE_VERSION_PREFIX="v"

  eval "$(direnv hook zsh)"
fi

##############################################################
# /etc/motd
##############################################################

if [ -e /etc/motd ]; then
  if ! cmp -s $HOME/.hushlogin /etc/motd; then
    tee $HOME/.hushlogin < /etc/motd
  fi
fi

##############################################################
# LOCAL.
##############################################################

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

