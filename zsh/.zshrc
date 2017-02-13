# vim:ft=zsh:

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

##############################################################
# zPlug.
##############################################################

export ZPLUG_HOME=$HOME/.zplug

if [[ ! -f $ZPLUG_HOME/init.zsh ]]; then
  if (( $+commands[git] )); then
    git clone https://github.com/zplug/zplug $ZPLUG_HOME
  else
    echo 'git not found' >&2
    exit 1
  fi
fi

source ~/.zplug/init.zsh

zplug 'zplug/zplug', hook-build:'zplug --self-manage'

# Make sure to use my fork
export _ZPLUG_PREZTO='ahmedelgabri/prezto'

zplug 'modules/environment', from:prezto
zplug 'modules/editor', from:prezto
# zplug 'zimframework/zim', from:github, use:'modules/input'
zplug 'zimframework/zim', from:github, use:'modules/history'
zplug 'zimframework/zim', from:github, use:'modules/directory'
zplug 'zimframework/zim', from:github, use:'modules/spectrum'
zplug 'modules/osx', from:prezto
zplug 'zimframework/zim', from:github, use:'modules/utility'
zplug 'modules/completion', from:prezto
zplug 'zimframework/zim', from:github, use:'modules/archive'
zplug 'zsh-users/zsh-syntax-highlighting', defer:2
zplug 'zsh-users/zsh-history-substring-search', on:'zsh-users/zsh-syntax-highlighting'
zplug 'modules/prompt', from:prezto
# zplug 'ahmedelgabri/pure', as:theme

source ./.zpreztorc

zplug 'junegunn/fzf', \
      as:command, \
      use:'bin/{fzf,fzf-tmux}', \
      hook-build:'./install'

zplug 'knu/z', use:'z.sh', defer:1


if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi

zplug load --verbose

##############################################################
# Prezto module overrides.
##############################################################
# Make some commands not show up in history
HISTIGNORE="ls:ls *:cd:cd -:pwd;exit:date:* --help"
HISTSIZE=100000
SAVEHIST=$HISTSIZE

##############################################################
# CONFIG.
##############################################################

for config (~/.dotfiles/zsh/config/*.zsh) source $config
for func (~/.dotfiles/zsh/config/functions/*.zsh) source $func

##############################################################
# TOOLS.
##############################################################

command -v grc >/dev/null && source "`brew --prefix`/etc/grc.bashrc"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


if [[ -n "$key_info" ]]; then
  # Emacs
  bindkey -M emacs "$key_info[Control]P" history-substring-search-up
  bindkey -M emacs "$key_info[Control]N" history-substring-search-down

  # Vi
  bindkey -M vicmd "k" history-substring-search-up
  bindkey -M vicmd "j" history-substring-search-down

  # Emacs and Vi
  for keymap in 'emacs' 'viins'; do
    bindkey -M "$keymap" "$key_info[Up]" history-substring-search-up
    bindkey -M "$keymap" "$key_info[Down]" history-substring-search-down
  done
fi

##############################################################
# LOCAL.
##############################################################

[ -f ~/.zstuff ] && source ~/.zstuff


