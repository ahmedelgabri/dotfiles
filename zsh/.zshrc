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

zplug "zplug/zplug", hook-build:"zplug --self-manage"

local -a zim_mods
zim_mods=(
  'environment'
  'input'
  'history'
  'directory'
  'spectrum'
  'utility'
  'prompt'
  'syntax-highlighting'
  'history-substring-search'
  'completion'
)

zplug "zimframework/zim", \
    depth:1, \
    use:"modules/{${(j:,:)zim_mods}}/init.zsh"

zplug "zimframework/zim", \
    depth:1, \
    use:"modules/{${(j:,:)zim_mods}}/functions/*", \
    lazy:1

zplug "modules/osx", depth:1, from:prezto
zplug "ahmedelgabri/pure", depth:1, use:"{async,pure}.zsh"
zplug "knu/z", use:"z.sh", depth:1, defer:1

if ! zplug check --verbose; then
  printf "Install? [y/N]: "
  if read -q; then
    echo; zplug install
  fi
fi

zplug load --verbose

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

# Zim settings
zprompt_theme='pure'
zcompdump_file=".zcompdump-${HOST}-${ZSH_VERSION}"
ztermtitle='%n@%m: %s'
zdouble_dot_expand='true'
zhighlighters=(main brackets pattern cursor root)

##############################################################
# TOOLS.
##############################################################

(( $+commands[grc] )) && source "`brew --prefix`/etc/grc.bashrc"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

##############################################################
# LOCAL.
##############################################################

[ -f ~/.zstuff ] && source ~/.zstuff


