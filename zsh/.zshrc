# vim:ft=zsh:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# ZPLUGIN https://github.com/zdharma/zplugin
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

NVM_NO_USE=true
zplugin load "lukechilds/zsh-nvm"

zplugin ice pick"async.zsh" src"pure.zsh"
zplugin load "ahmedelgabri/pure"

zplugin ice "rupa/z" pick"z.sh"
zplugin load "rupa/z"

zplugin load "zsh-users/zsh-history-substring-search"

# https://github.com/zdharma/zplugin#turbo-mode-zsh--53
zplugin ice wait"1" lucid atload"_zsh_autosuggest_start"
zplugin load "zsh-users/zsh-autosuggestions"

zplugin ice wait"0" lucid blockf
zplugin load "zsh-users/zsh-completions"

zplugin ice wait"0" lucid atinit"zpcompinit; zpcdreplay"
zplugin load "zdharma/fast-syntax-highlighting"

##############################################################
# PLUGINS VARS & SETTINGS
##############################################################

ZSH_AUTOSUGGEST_USE_ASYNC=true

# bind UP and DOWN keys
bindkey "${terminfo[kcuu1]}" history-substring-search-up
bindkey "${terminfo[kcud1]}" history-substring-search-down

# bind UP and DOWN arrow keys (compatibility fallback)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

##############################################################
# CONFIG.
##############################################################

source ${ZDOTDIR}/rc.d/aliases.zsh
for func (${ZDOTDIR}/rc.d/functions/*.zsh) source $func

##############################################################
# TOOLS.
##############################################################

(( $+commands[grc] )) && source "${HOMEBREW_ROOT:-/usr/local}/etc/grc.bashrc"
[ -f ${HOME}/.fzf.zsh ] && source ${HOME}/.fzf.zsh

##############################################################
# direnv.
##############################################################

if [ $(command -v direnv) ]; then
  export NODE_VERSIONS="${HOME}/.nvm/versions/node"
  export NODE_VERSION_PREFIX="v"

  eval "$(direnv hook zsh)"
fi

##############################################################
# /etc/motd
##############################################################

if [ -e /etc/motd ]; then
  if ! cmp -s ${HOME}/.hushlogin /etc/motd; then
    tee ${HOME}/.hushlogin < /etc/motd
  fi
fi

##############################################################
# Custom completions init.
##############################################################

[ -f ${ZDOTDIR:-${HOME}}/rc.d/completions/init.zsh ] && source ${ZDOTDIR:-${HOME}}/rc.d/completions/init.zsh

##############################################################
# LOCAL.
##############################################################

if [ -f ${HOME}/.zshrc.local ]; then
  source ${HOME}/.zshrc.local
else
  if [[ -z "${HOMEBREW_GITHUB_API_TOKEN}" && -z "${GITHUB_TOKEN}" && -z "${GITHUB_USER}" ]]; then
    echo "These ENV vars are not set: HOMEBREW_GITHUB_API_TOKEN, GITHUB_TOKEN & GITHUB_USER. Add them to ~/.zshrc.local"
  fi
fi

