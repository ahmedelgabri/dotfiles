#!/bin/bash

THEMES=(
  "https://raw.githubusercontent.com/morhetz/gruvbox-generalized/master/iterm2/gruvbox-light.itermcolors"
  "https://raw.githubusercontent.com/morhetz/gruvbox-generalized/master/iterm2/gruvbox-dark.itermcolors"
  "https://raw.githubusercontent.com/chriskempson/base16-iterm2/master/base16-eighties.dark.256.itermcolors"
  "https://raw.githubusercontent.com/chriskempson/base16-iterm2/master/base16-ocean.dark.256.itermcolors"
  "https://raw.githubusercontent.com/w0ng/dotfiles/master/iterm2/hybrid.itermcolors"
  "https://raw.githubusercontent.com/w0ng/dotfiles/master/iterm2/hybrid-reduced-contrast.itermcolors"
  "https://raw.githubusercontent.com/anunez/one-dark-iterm/master/one-dark.itermcolors"
  "https://raw.githubusercontent.com/oskarkrawczyk/honukai-iterm-zsh/master/honukai.itermcolors"
  "https://raw.githubusercontent.com/joshdick/onedark.vim/master/term/One%20Dark.terminal"
  "https://raw.githubusercontent.com/tyrannicaltoucan/vim-deep-space/master/term/deep-space.itermcolors"
)

# I need to find a way to import them in using the script
for t in "${THEMES[@]}"; do
  local NAME="$(basename "$t")"
  wget -O "$HOME/.dotfiles/iterm2/$NAME" "$t"
done

unset -v THEMES
