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
  ${GHOSTTY_BIN_DIR}(N-/)
  ${ZDOTDIR}/bin
  ${HOME}/.local/bin(N-/)
  # ${CARGO_HOME}/bin(N-/)
  ${GOBIN}(N-/)
  $path
  # For M1/2 machines
  /opt/homebrew/bin(N-/)
  /usr/local/{bin,sbin}
)

fpath=(
  ${ZDOTDIR}/functions
  $fpath
)

autoload -Uz ${ZDOTDIR}/functions/**/*(N:t)
