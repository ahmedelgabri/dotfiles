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
typeset -gU fpath mailpath path

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

fpath=(
  ${ZDOTDIR}/functions(N-/)
  ${ZDOTDIR}/completions(N-/)
  $fpath
)

autoload -Uz ${ZDOTDIR}/functions/**/*(N:t)

# Set the list of directories that Zsh searches for programs.
path=(
  ${ZDOTDIR}/bin(N-/)
  ${HOME}/.local/bin(N-/)
  # ${CARGO_HOME}/bin(N-/)
  ${GOBIN}(N-/)
  $path
  /usr/local/{bin,sbin} # This looks hacky...
)

# for config (${ZDOTDIR}/config/*.zsh) source $config
