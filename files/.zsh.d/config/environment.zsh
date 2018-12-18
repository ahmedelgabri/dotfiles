#
# generic options and environment settings
#

# Use smart URL pasting and escaping.
autoload -Uz bracketed-paste-url-magic && zle -N bracketed-paste bracketed-paste-url-magic
autoload -Uz url-quote-magic && zle -N self-insert url-quote-magic

# Treat single word simple commands without redirection as candidates for resumption of an existing job.
setopt AUTO_RESUME

# Allow comments starting with `#` even in interactive shells.
setopt INTERACTIVE_COMMENTS

# disable start (C-s) and stop (C-q) characters
setopt NO_FLOW_CONTROL

# Suggest command corrections
setopt CORRECT

# List jobs in the long format by default.
setopt LONG_LIST_JOBS

# Report the status of background jobs immediately, rather than waiting until just before printing a prompt.
setopt NOTIFY

# Prevent runing all background jobs at a lower priority.
setopt NO_BG_NICE

# Prevent reporting the status of background and suspended jobs before exiting a shell with job control.
# NO_CHECK_JOBS is best used only in combination with NO_HUP, else such jobs will be killed automatically.
setopt NO_CHECK_JOBS

# Prevent sending the HUP signal to running jobs when the shell exits.
setopt NO_HUP

# Remove path separtor from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

# Set less or more as the default pager.
if (( ! ${+PAGER} )); then
  if (( ${+commands[less]} )); then
    export PAGER=less
  else
    export PAGER=more
  fi
fi

# sets the window title and updates upon directory change
# more work probably needs to be done here to support multiplexers
if (( ${+ztermtitle} )); then
  case ${TERM} in
    xterm*|*rxvt)
      precmd() { print -Pn "\e]0;${ztermtitle}\a" }
      precmd  # we execute it once to initialize the window title
      ;;
  esac
fi

##############################################################
# GLOBAL CONFIG
##############################################################


if [[ ! -n "$TMUX" && "$TERM" == kitty* ]]; then
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
case $EDITOR in
    nvim) export MANPAGER="nvim +Man!" ;;
     vim) export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man' -\"" ;;
       *) export MANPAGER='less' ;;
esac
export MANWIDTH=120¬

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
