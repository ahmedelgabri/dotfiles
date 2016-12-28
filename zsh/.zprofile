# vim:ft=zsh:
#
# Executes commands at login pre-zshrc.
#

##############################################################
# DEFINES ENVIRONMENT VARIABLES.
##############################################################
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
command -v nvim >/dev/null && export EDITOR=nvim || export EDITOR=vim
export VISUAL=$EDITOR
export GIT_EDITOR=$EDITOR
export PAGER='less'

#
# Language
#

if [[ -z "$LANG" ]]; then
  export LANG='en_US.UTF-8'
  export LC_ALL='en_US.UTF-8'
fi

# 10ms for key sequences
KEYTIMEOUT=1

##############################################################
# PATH.
##############################################################
fpath=('/usr/local/share/zsh/site-functions' $fpath)

# GNU Coreutils
export MANPATH="/usr/local/opt/coreutils/libexec/gnuman:$MANPATH"

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the the list of directories that cd searches.
# cdpath=(
#   $cdpath
# )

# Set the list of directories that Zsh searches for programs.
path=(
  /usr/local/{bin,sbin}
  "/usr/local/opt/coreutils/libexec/gnubin"
  /usr/local/Cellar/git
  ${HOME}/.tmuxifier/bin
  ${HOME}/.dotfiles/bin
  $path
)

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
