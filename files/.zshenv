# set -x
# setopt NO_GLOBAL_RCS

export LANG=en_US.UTF-8
export LC_ALL=$LANG

# using prompt expansion and modifiers to get
# https://github.com/filipekiss/dotfiles/commit/c7288905178be3e6c378cc4dea86c1a80ca60660#r29121191
# man zshexpn
# realpath(dirname(absolute path to this file)
# export ZDOTDIR="${${(%):-%N}:A:h}"
export ZDOTDIR="${HOME}/.zsh.d"
export OSTYPE=$(uname -s)
export HOSTNAME=$(hostname)
export XDG_CONFIG_HOME="${HOME}/.config"
export DOTFILES="${HOME}/.dotfiles"
export GOPATH="${HOME}/.go"
export PROJECTS="${HOME}/Sites/dev"
export PERSONAL_STORAGE="${HOME}/Box Sync"
export PERSONAL_ENVS="${PERSONAL_STORAGE}/dotfiles/zsh_personal"
export NOTE_DIR="${PERSONAL_STORAGE}/notes"

[[ -x /usr/local/bin/brew ]] && export HOMEBREW_ROOT=$(/usr/local/bin/brew --prefix)

# Ensure that a non-login, non-interactive shell has a defined environment.
# (Only once) if it was not sourced before, becuase .zshenv is always sourced
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
