# vim:ft=zsh:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# zPlug.
##############################################################
if [[ ! -f ~/antigen.zsh ]]; then
  curl -sL --proto-redir -all,https git.io/antigen > ~/antigen.zsh
fi

source ~/antigen.zsh

NVM_NO_USE=true

antigen bundles <<EOBUNDLES
lukechilds/zsh-nvm
zimfw/zimfw
knu/z
lukechilds/zsh-better-npm-completion
molovo/tipz
zdharma/fast-syntax-highlighting
zsh-users/zsh-autosuggestions
zdharma/fast-syntax-highlighting
zsh-users/zsh-history-substring-search
EOBUNDLES

antigen bundle mafredri/zsh-async
antigen theme ahmedelgabri/pure
# Must be the last?
antigen bundle "zsh-users/zsh-completions"
antigen apply

# bind UP and DOWN keys
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# bind UP and DOWN arrow keys (compatibility fallback)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

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

