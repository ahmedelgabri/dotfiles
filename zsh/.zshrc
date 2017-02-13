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
zplug 'modules/history', from:prezto
zplug 'modules/directory', from:prezto
zplug 'modules/spectrum', from:prezto
zplug 'modules/osx', from:prezto
zplug 'modules/utility', from:prezto
zplug 'modules/completion', from:prezto
zplug 'modules/archive', from:prezto
zplug 'zsh-users/zsh-syntax-highlighting', defer:2
zplug 'zsh-users/zsh-history-substring-search', on:'zsh-users/zsh-syntax-highlighting'
zplug 'modules/prompt', from:prezto

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

##############################################################
# LOCAL.
##############################################################

[ -f ~/.zstuff ] && source ~/.zstuff


