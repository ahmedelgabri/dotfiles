export COLORTERM="truecolor"
# TODO: Look into caching it
eval $( dircolors -b $HOME/.config/dircolors )
# Better spell checking & auto correction prompt
export SPROMPT="zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?"
# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS="-F -g -i -M -R -S -w -X -z-4"
export KEYTIMEOUT="1"
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

export DOTFILES="$HOME/.dotfiles"
export PROJECTS="$HOME/Sites/personal/dev"
export WORK="$HOME/Sites/work"
export PERSONAL_STORAGE="$HOME/Sync"
export NOTES_DIR="$PERSONAL_STORAGE/notes"
export ZK_NOTEBOOK_DIR="$NOTES_DIR"
# I use a single zk notes dir, so set it and forget
export ZK_NOTEBOOK_DIR=$NOTES_DIR

############### APPS/POGRAMS XDG SPEC CLEANUP
export RLWRAP_HOME="$XDG_DATA_HOME/rlwrap"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export ELINKS_CONFDIR="$XDG_CONFIG_HOME/elinks"
export _ZO_DATA_DIR="$XDG_CONFIG_HOME/zoxide"
export KITTY_LISTEN_ON="unix:/tmp/kitty"

############### Telemetry
export DO_NOT_TRACK="1" # Future proof? https://consoledonottrack.com/
export HOMEBREW_NO_ANALYTICS="1"
export GATSBY_TELEMETRY_DISABLED="1"
export ADBLOCK="true"

############### Homebrew
export HOMEBREW_INSTALL_BADGE="⚽️"

############### Pure
export PURE_GIT_UP_ARROW="🠥"
export PURE_GIT_DOWN_ARROW="🠧"
export PURE_GIT_BRANCH="  "

# Remove path separtor from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

############### PAGER
# Set less or more as the default pager.
if (( ! ${+PAGER} )); then
  if (( ${+commands[less]} )); then
    export PAGER=less
  else
    export PAGER=more
  fi
fi

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

############### Temporary Files
if [[ ! -d "$TMPDIR" ]]; then
  export TMPDIR="/tmp/$LOGNAME"
  mkdir -p -m 700 "$TMPDIR"
fi

TMPPREFIX="${TMPDIR%/}/zsh";


# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath manpath path

##############################################################
# PATH.
# (N-/): do not register if the directory does not exists
# (Nn[-1]-/)
#
#  N   : NULL_GLOB option (ignore path if the path does not match the glob)
#  n   : Sort the output
#  [-1]: Select the last item in the array
#  -   : follow the symbol links
#  /   : ignore files
#  t   : tail of the path
##############################################################

path=(
  ${ZDOTDIR}/bin
  ${HOME}/.local/bin(N-/)
  # ${CARGO_HOME}/bin(N-/)
  ${GOBIN}(N-/)
  $path
  /usr/local/{bin,sbin}
)
