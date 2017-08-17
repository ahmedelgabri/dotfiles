# vim:ft=zsh:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# zPlug.
##############################################################

if [[ ! -f ~/.zplug/init.zsh ]]; then
  if (( $+commands[git] )); then
    git clone https://github.com/zplug/zplug ~/.zplug
  else
    echo 'git not found' >&2
    exit 1
  fi
fi

source ~/.zplug/init.zsh

zplug "zplug/zplug", hook-build:"zplug --self-manage"
NVM_LAZY_LOAD=true
# NVM_AUTO_USE=true
zplug "lukechilds/zsh-nvm"

zplug "zimframework/zim", depth:1, use:"init.zsh", hook-build:"ln -sf $ZPLUG_ROOT/repos/zimframework/zim ~/.zim"
# Zim settings
zmodules=(
  directory
  environment
  history
  meta
  input
  utility
  spectrum
  syntax-highlighting
  history-substring-search
  prompt
  completion
)

zplug "modules/osx", depth:1, from:prezto
zplug "ahmedelgabri/pure", depth:1, use:"{async,pure}.zsh"
zplug "knu/z", use:"z.sh", depth:1, defer:1
zplug "lukechilds/zsh-better-npm-completion", defer:1
zplug "maxmellon/yarn_completion", defer:1
zplug "zsh-users/zsh-autosuggestions", defer:1

if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi

# zplug load --verbose
zplug load

zprompt_theme="pure"
ztermtitle="%n@%m:%~"
zdouble_dot_expand="true"
zhighlighters=(main brackets pattern cursor root)
ZSH_AUTOSUGGEST_USE_ASYNC=true
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=default,fg=red,bold'
HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=default,fg=blue,bold'

##############################################################
# CONFIG.
##############################################################

for config (~/.dotfiles/zsh/config/*.zsh) source $config
for func (~/.dotfiles/zsh/config/functions/*.zsh) source $func

##############################################################
# ENV OVERRIDES
##############################################################
# Make some commands not show up in history
HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
HISTSIZE=100000
SAVEHIST=$HISTSIZE

##############################################################
# TOOLS.
##############################################################

(( $+commands[grc] )) && source "`brew --prefix`/etc/grc.bashrc"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##############################################################
# LOCAL.
##############################################################

[ -f ~/.zshrc.local ] && source ~/.zshrc.local

