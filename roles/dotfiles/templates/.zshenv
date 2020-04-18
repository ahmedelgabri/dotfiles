# {{ ansible_managed }}
##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof` also the same needs to happend in `.zshrc`
# zmodload zsh/zprof
#
##############################################################

# set -x
# setopt NO_GLOBAL_RCS

export COLORTERM='truecolor'

# Remove path separtor from WORDCHARS.
WORDCHARS=${WORDCHARS//[\/]}

############### PAGER
# Set less or more as the default pager.
if (( ! ${+PAGER} )); then
  if (( ${+commands[less]} )); then
    export PAGER=less
  else
    export PAGER=more
  fi
fi

# Better spell checking & auto correction prompt
export SPROMPT="zsh: correct %F{red}'%R'%f to %F{blue}'%r'%f [%B%Uy%u%bes, %B%Un%u%bo, %B%Ue%u%bdit, %B%Ua%u%bbort]? "

# Browser
if [ "$(uname)" = "Darwin" ]; then
  export BROWSER='open'
fi

############### Less
# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# Set the Less input preprocessor.
# Try both `lesspipe` and `lesspipe.sh` as either might exist on a system.
if (( $#commands[(i)lesspipe(|.sh)] )); then
  export LESSOPEN="| /usr/bin/env $commands[(i)lesspipe(|.sh)] %s 2>&-"
fi

export MANWIDTH=120

############### Temporary Files
if [[ ! -d "$TMPDIR" ]]; then
  export TMPDIR="/tmp/$LOGNAME"
  mkdir -p -m 700 "$TMPDIR"
fi

TMPPREFIX="${TMPDIR%/}/zsh"

export KEYTIMEOUT=1

export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-$HOME/.config}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-$HOME/.cache}
export XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

# using prompt expansion and modifiers to get
# https://github.com/filipekiss/dotfiles/commit/c7288905178be3e6c378cc4dea86c1a80ca60660#r29121191
# man zshexpn
# realpath(dirname(absolute path to this file)
# export ZDOTDIR="${${(%):-%N}:A:h}"
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

export MAILDIR="${HOME}/.mail" # will be picked up by .notmuch-config for database.path
export DOTFILES="${HOME}/.dotfiles"
export PROJECTS="${HOME}/Sites/personal/dev"
export WORK="${HOME}/Sites/work"
export PERSONAL_STORAGE="${HOME}/Box"
export NOTES_DIR="${PERSONAL_STORAGE}/notes"

############### APPS/POGRAMS XDG SPEC CLEANUP
export GOPATH="${XDG_DATA_HOME}/go"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GNUPGHOME="${XDG_CONFIG_HOME}/gnupg"
export NOTMUCH_CONFIG="${XDG_CONFIG_HOME}/notmuch/config"
export BAT_CONFIG_PATH="${XDG_CONFIG_HOME}/bat/config"
export RIPGREP_CONFIG_PATH="${XDG_CONFIG_HOME}/ripgrep/config"
export WEECHAT_HOME="${XDG_CONFIG_HOME}/weechat"
export N_PREFIX="${XDG_DATA_HOME}/n"
export PYTHONSTARTUP="${XDG_CONFIG_HOME}/python/config.py"
export RLWRAP_HOME="${XDG_DATA_HOME}/rlwrap"
export AWS_SHARED_CREDENTIALS_FILE="${XDG_CONFIG_HOME}/aws/credentials"
export AWS_CONFIG_FILE="${XDG_CONFIG_HOME}/aws/config"
export DOCKER_CONFIG="${XDG_CONFIG_HOME}/docker"
export ELINKS_CONFDIR="${XDG_CONFIG_HOME}/elinks"
export _JAVA_OPTIONS=-Djava.util.prefs.userRoot="${XDG_CONFIG_HOME}/java"
export RUSTUP_HOME="${XDG_DATA_HOME}/rustup"

# export MAILCAP="${XDG_CONFIG_HOME}/mailcap" # elinks, w3m
# export MAILCAPS="$MAILCAP"   # Mutt, pine

############### Telemetry
export DO_NOT_TRACK=1 # Future proof? https://consoledonottrack.com/
export HOMEBREW_NO_ANALYTICS=1
export GATSBY_TELEMETRY_DISABLED=1

export ADBLOCK=1

############### Go
export GOBIN="${GOPATH}/bin"

############### Homebrew
export HOMEBREW_INSTALL_BADGE="⚽️"
export HOMEBREW_PREFIX=${HOMEBREW_PREFIX:-"/usr/local"}
export HOMEBREW_CELLAR=${HOMEBREW_CELLAR:-"/usr/local/Cellar"}
export HOMEBREW_REPOSITORY=${HOMEBREW_REPOSITORY:-"/usr/local/Homebrew"}

############### Weechat
export WEECHAT_PASSPHRASE=`security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`

############### Direnv
export NODE_VERSIONS="${N_PREFIX}/versions/node"
export NODE_VERSION_PREFIX=""

############### Pure
export PURE_GIT_UP_ARROW='🠥'
export PURE_GIT_DOWN_ARROW='🠧'
export PURE_GIT_BRANCH="  "

############### Autosuggest
export ZSH_AUTOSUGGEST_USE_ASYNC=true

{% if github_username != '' %}
export GITHUB_USER="{{ github_username }}"
{% endif %}

# Ensure that a non-login, non-interactive shell has a defined environment.
# (Only once) if it was not sourced before, becuase .zshenv is always sourced
if [[ ( "$SHLVL" -eq 1 && ! -o LOGIN ) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi
