#
# Editor and input char assignment
#

if [ -t 0 ]; then
  stty -ixon # allow C-s and C-q to be used for things
fi

bindkey -v

zmodload -F zsh/terminfo +b:echoti +p:terminfo

# Bind the keys

# Expandpace.
bindkey ' ' magic-space

# Clear
bindkey '\C-L' clear-screen

# Bind Shift + Tab to go to the previous menu item.
[[ -n "${terminfo[kcbt]}" ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd '!' edit-command-line
