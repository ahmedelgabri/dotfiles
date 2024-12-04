export LS_COLORS=$(vivid generate ~/.config/vivid/theme.yml)
export COLORTERM="truecolor"
# Better spell checking & auto correction prompt
export SPROMPT="zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]?"
# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS="-F -g -i -M -R -S -w -X -z-4"
export KEYTIMEOUT=1
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export ZCOMPDUMP_PATH="$ZDOTDIR/.zcompdump"

export DOTFILES="$HOME/.dotfiles"
export PROJECTS="$HOME/Sites/personal/dev"
export WORK="$HOME/Sites/work"
export PERSONAL_STORAGE="$HOME/Sync"
export NOTES_DIR="$PERSONAL_STORAGE/notes"
# I use a single zk notes dir, so set it and forget
export ZK_NOTEBOOK_DIR=$NOTES_DIR
# export HOST_CONFIGS="$XDG_DATA_HOME/$(hostname)"

############### APPS/POGRAMS XDG SPEC CLEANUP
export RLWRAP_HOME="$XDG_DATA_HOME/rlwrap"
export AWS_SHARED_CREDENTIALS_FILE="$XDG_CONFIG_HOME/aws/credentials"
export AWS_CONFIG_FILE="$XDG_CONFIG_HOME/aws/config"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export ELINKS_CONFDIR="$XDG_CONFIG_HOME/elinks"
export _ZO_DATA_DIR="$XDG_CONFIG_HOME/zoxide"
export KITTY_LISTEN_ON="unix:/tmp/kitty"
export EZA_COLORS="ur=35;nnn:gr=35;nnn:tr=35;nnn:uw=34;nnn:gw=34;nnn:tw=34;nnn:ux=36;nnn:ue=36;nnn:gx=36;nnn:tx=36;nnn:uu=36;nnn:uu=38;5;235:da=38;5;238"
export EZA_ICON_SPACING=2

############### Telemetry
export DO_NOT_TRACK=1 # Future proof? https://consoledonottrack.com/
export HOMEBREW_NO_ANALYTICS=1
export GATSBY_TELEMETRY_DISABLED=1
export NEXT_TELEMETRY_DISABLED=1
export ADBLOCK="true"

############### Homebrew
export HOMEBREW_INSTALL_BADGE="⚽️"

############### Pure
export PURE_GIT_UP_ARROW="🠥"
export PURE_GIT_DOWN_ARROW="🠧"
export PURE_GIT_BRANCH="  "

# Remove path separator from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

############### PAGER
export PAGER=less
export LESS_TERMCAP_mb=$'\E[1;31m'   # Begins blinking.
export LESS_TERMCAP_md=$'\E[1;31m'   # Begins bold.
export LESS_TERMCAP_me=$'\E[0m'      # Ends mode.
export LESS_TERMCAP_se=$'\E[0m'      # Ends standout-mode.
export LESS_TERMCAP_so=$'\E[7m'      # Begins standout-mode.
export LESS_TERMCAP_ue=$'\E[0m'      # Ends underline.
export LESS_TERMCAP_us=$'\E[1;32m'   # Begins underline.

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi


############### PLUGINS

PURE_SYMBOLS=("λ" "ϟ" "▲" "∴" "→" "»" "৸")
# Arrays in zsh starts from 1
export PURE_PROMPT_SYMBOL="${PURE_SYMBOLS[$RANDOM % ${#PURE_SYMBOLS[@]} + 1]}"
# zstyle :prompt:pure:path color 240
# zstyle :prompt:pure:git:branch color blue
# zstyle :prompt:pure:git:dirty color red
# zstyle :prompt:pure:git:action color 005
# zstyle :prompt:pure:prompt:success color 003

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
  /opt/homebrew/bin(N-/) # For M1/2 machines
  /usr/local/{bin,sbin}
)

fpath=(
  ${ZDOTDIR}/functions
  $fpath
)

autoload -Uz ${ZDOTDIR}/functions/**/*(N:t)
