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
