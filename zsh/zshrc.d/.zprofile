# vim:ft=zsh:
#
# Executes commands at login pre-zshrc.
#

export DOTFILES=$HOME/.dotfiles

##############################################################
# CONFIG.
# ##############################################################

for config (${DOTFILES}/zsh/zshrc.d/config/*.zsh) source $config

##############################################################
# GLOBAL CONFIG (@NOTE: maybe move them to config files)
##############################################################

if [ -n "$TMUX" ]; then
  export TERM=tmux-256color
else
  export TERM=xterm-256color
fi

# Better spell checking & auto correction prompt
export SPROMPT="zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "

#
# Browser
#

if [[ "$OSTYPE" == darwin* ]]; then
  export BROWSER='open'
fi

#
# Editors
#

# Set neovim as EDITOR if it's available, otherwise use vim
(( $+commands[nvim] )) && export EDITOR=nvim || export EDITOR=vim
export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR
export PAGER='less'

#
# Language
#

export LANG=en_US.UTF-8
export LC_ALL=$LANG

# 10ms for key sequences
KEYTIMEOUT=1

export GPG_TTY=$(tty)

(( $+commands[brew] )) && export HOMEBREW_ROOT=$(brew --prefix)


##############################################################
# PATH.
##############################################################
fpath=(
  ${ZDOTDIR:-${HOME}}/completions
  '/usr/local/share/zsh/site-functions'
  $fpath
)

# GNU Coreutils
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"
case $EDITOR in
    nvim) export MANPAGER="nvim +'set ft=man' -" ;;
     vim) export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man' -\"" ;;
       *) export MANPAGER='less' ;;
esac
export MANWIDTH=120

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the the list of directories that cd searches.
cdpath=(
  $cdpath
)

# Set the list of directories that Zsh searches for programs.
path=(
  ${DOTFILES}/bin
  ./node_modules/.bin
  ${HOMEBREW_ROOT:-/usr/local}/{bin,sbin}
  ${HOMEBREW_ROOT:-/usr/local}/opt/python/libexec/bin
  ${HOMEBREW_ROOT:-/usr/local}/opt/coreutils/libexec/gnubin
  ${HOMEBREW_ROOT:-/usr/local}/opt/curl/bin
  ${HOMEBREW_ROOT:-/usr/local}/Cellar/git
  $path
)

if (( $+commands[yarn] )); then
  path+=($(yarn global dir)/node_modules/.bin)
fi

if (( $+commands[python] )) then
  path+=($(python -m site --user-base)/bin)
fi

if (( $+commands[python3] )) then
  path+=($(python3 -m site --user-base)/bin)
fi

if [[ -d "${HOME}/.cargo/bin" ]]; then
  path+=(${HOME}/.cargo/bin)
fi

if (( $+commands[go] )) then
  export GOPATH="${HOME}/.go"
  path+=(${GOPATH}/bin)
fi

#
# Less
#

# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

#
# Temporary Files
#

if [[ ! -d "$TMPDIR" ]]; then
  export TMPDIR="/tmp/$LOGNAME"
  mkdir -p -m 700 "$TMPDIR"
fi

TMPPREFIX="${TMPDIR%/}/zsh"


##############################################################
# Custom/Plugins
###############################################################
export FZF_DEFAULT_OPTS='--min-height 30 --height 50% --reverse --tabstop 2 --multi --margin 0,3,3,3 --preview-window wrap'
export FZF_DEFAULT_COMMAND='\rg --no-messages --hidden --no-ignore-vcs --files --follow --glob "!.git/*" --glob "!node_modules/*"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS='--preview "(highlight -O ansi -l {} || cat {} || tree -C {}) 2> /dev/null | head -200" --bind "?:toggle-preview"'
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind '?:toggle-preview' --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -200'"
export FZF_VIM_LOG=$(git config --get alias.l | awk '{$1=""; print $0;}' | tr -d '\r')

export HOMEBREW_INSTALL_BADGE="⚽️"
export HOMEBREW_NO_ANALYTICS=1
export WEECHAT_PASSPHRASE=`security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`
# `cd ~df` or `z ~df`
# hash -d df=~/.dotfiles

SYMBOLS=(
"λ"
"ϟ"
"▲"
"∴"
"→"
"»"
"৸"
)

# Arrays in zsh starts from 1
export PURE_PROMPT_SYMBOL="${SYMBOLS[$RANDOM % ${#SYMBOLS[@]} + 1]}"

##############################################################
# Python
###############################################################
export PYTHONSTARTUP=${HOME}/.pyrc.py
