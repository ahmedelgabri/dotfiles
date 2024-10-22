#
# Editor and input char assignment
#

if [ -t 0 ]; then
	stty -ixon # allow C-s and C-q to be used for things
fi

bindkey -v

# Use human-friendly identifiers.
zmodload -F zsh/terminfo +b:echoti +p:terminfo
typeset -gA key_info
key_info=(
  'Control'      '\C-'
  'ControlLeft'  '\e[1;5D \e[5D \e\e[D \eOd \eOD'
  'ControlRight' '\e[1;5C \e[5C \e\e[C \eOc \eOC'
  'Escape'       '\e'
  'Meta'         '\M-'
  'Backspace'    ${terminfo[kbs]}
  'BackTab'      ${terminfo[kcbt]}
  'Left'         ${terminfo[kcub1]}
  'Down'         ${terminfo[kcud1]}
  'Right'        ${terminfo[kcuf1]}
  'Up'           ${terminfo[kcuu1]}
  'Delete'       ${terminfo[kdch1]}
  'End'          ${terminfo[kend]}
  'F1'           ${terminfo[kf1]}
  'F2'           ${terminfo[kf2]}
  'F3'           ${terminfo[kf3]}
  'F4'           ${terminfo[kf4]}
  'F5'           ${terminfo[kf5]}
  'F6'           ${terminfo[kf6]}
  'F7'           ${terminfo[kf7]}
  'F8'           ${terminfo[kf8]}
  'F9'           ${terminfo[kf9]}
  'F10'          ${terminfo[kf10]}
  'F11'          ${terminfo[kf11]}
  'F12'          ${terminfo[kf12]}
  'Home'         ${terminfo[khome]}
  'Insert'       ${terminfo[kich1]}
  'PageDown'     ${terminfo[knp]}
  'PageUp'       ${terminfo[kpp]}
)

# Bind the keys

if [[ ${zdouble_dot_expand} == 'true' ]]; then
  double-dot-expand() {
    if [[ ${LBUFFER} == *.. ]]; then
      LBUFFER+='/..'
    else
      LBUFFER+='.'
    fi
  }
  zle -N double-dot-expand
  bindkey '.' double-dot-expand
fi

# Expandpace.
bindkey ' ' magic-space

# Clear
bindkey "${key_info[Control]}L" clear-screen

# Bind Shift + Tab to go to the previous menu item.
[[ -n ${key_info[BackTab]} ]] && bindkey ${key_info[BackTab]} reverse-menu-complete

autoload -Uz is-at-least && if ! is-at-least 5.3; then
  # Redisplay after completing, and avoid blank prompt after <Tab><Tab><Ctrl-C>
  expand-or-complete-with-redisplay() {
    print -Pn '...'
    zle expand-or-complete
    zle redisplay
  }
  zle -N expand-or-complete-with-redisplay
  bindkey "${key_info[Control]}I" expand-or-complete-with-redisplay
fi

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd '!' edit-command-line
