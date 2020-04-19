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
#  t   : tail of the path
##############################################################

fpath=(
  ${ZDOTDIR:-${DOTFILES}/roles/dotfiles/files/.config/zsh}/functions(N-/)
  ${ZDOTDIR:-${DOTFILES}/roles/dotfiles/files/.config/zsh}/completions(N-/)
  /usr/local/share/zsh/site-functions(N-/)
  $fpath
)

autoload -Uz ${ZDOTDIR:-${DOTFILES}/roles/dotfiles/files/.config/zsh}/functions/**/*(N:t) promptinit
promptinit # enables prompt command which is useful to list installed prompts

manpath=(
  ${HOMEBREW_PREFIX}/opt/*/libexec/gnuman(N-/)
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
  ${ZDOTDIR:-${DOTFILES}/roles/dotfiles/files/.config/zsh}/bin(N-/)
  ${HOME}/.local/bin(N-/)
  ${HOMEBREW_PREFIX}/opt/curl/bin(N-/)
  ${HOMEBREW_PREFIX}/opt/openssl@*/bin(Nn[-1]-/)
  ${HOMEBREW_PREFIX}/opt/gnu-sed/libexec/gnubin(N-/)
  ${HOMEBREW_PREFIX}/opt/coreutils/libexec/gnubin(N-/)
  ${HOMEBREW_PREFIX}/opt/python/libexec/bin(N-/)
  ${HOME}/.cargo/bin(N-/)
  ${GOBIN}(N-/)
  ${HOME}/Library/Python/3.*/bin(Nn[-1]-/)
  ${HOME}/Library/Python/2.*/bin(Nn[-1]-/)
  ${HOMEBREW_PREFIX}/opt/ruby/bin(N-/)
  ${HOMEBREW_PREFIX}/lib/ruby/gems/*/bin(Nn[-1]-/)
  /usr/local/{bin,sbin}
  ${HOMEBREW_CELLAR}/git/*/share/git-core/contrib/git-jump(Nn[-1]-/)
  $path
)

for config (${ZDOTDIR}/config/*.zsh) source $config
