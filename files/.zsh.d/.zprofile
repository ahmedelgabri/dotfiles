# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath manpath mailpath path

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
##############################################################

fpath=(
  ${ZDOTDIR:-${HOME}}/completions(N-/)
  /usr/local/share/zsh/site-functions(N-/)
  $fpath
)

manpath=(
  ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnuman(N-/)
  $manpath
)

infopath=(
 /usr/local/share/info
 $infopath
)

# Set the the list of directories that cd searches.
cdpath=(
  $cdpath
)

# Set the list of directories that Zsh searches for programs.
path=(
  ./node_modules/.bin
  ${DOTFILES}/extra/bin(N-/)
  ${HOME}/.local/bin(N-/)
  /usr/local/opt/curl/bin(N-/)
  /usr/local/opt/openssl/bin(N-/)
  ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin(N-/)
  ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin(N-/)
  ${HOMEBREW_PREFIX}/opt/python/libexec/bin(N-/)
  ${HOME}/.cargo/bin(N-/)
  ${GOPATH}/bin(N-/)
  ${HOME}/Library/Python/3.*/bin(Nn[-1]-/)
  ${HOME}/Library/Python/2.*/bin(Nn[-1]-/)
  /usr/local/{bin,sbin}
  $path
)

for config (${ZDOTDIR}/config/*.zsh) source $config
