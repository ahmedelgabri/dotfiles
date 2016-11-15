# https://github.com/wincent/wincent/blob/a98944d57a8c8bd9b034da555932079f35f8769d/roles/dotfiles/files/.zshrc#L157-L166
# Make CTRL-Z background things and unbackground them.
function fg-bg() {
  if [[ $#BUFFER -eq 0 ]]; then
    fg
  else
    zle push-input
  fi
}
zle -N fg-bg
bindkey '^Z' fg-bg

