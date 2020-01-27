# vim:ft=zsh:
# setopt warn_create_global

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

# Wrapping my config in a ZSH Anonymous Functions http://zsh.sourceforge.net/Doc/Release/Functions.html#Anonymous-Functions
# To create a closure to not leak local variables
function {
  # To override Catalina /etc/zshrc
  HISTSIZE=1000000
  SAVEHIST=$HISTSIZE
  HISTFILE="${XDG_DATA_HOME:-$HOME}/.zsh_history"

  ##############################################################
  # ZINIT https://github.com/zdharma/zinit
  ##############################################################

  local __ZINIT="${ZDOTDIR:-$HOME}/.zinit/bin/zinit.zsh"

  if [[ ! -f "$__ZINIT" ]]; then
    if (( $+commands[curl] )); then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zinit/master/doc/install.sh)"
    else
      echo 'curl not found' >&2
      exit 1
    fi
  fi

  source "$__ZINIT"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # Shell {{{
    zinit ice svn
    zinit snippet OMZ::plugins/gpg-agent

    zinit load https://github.com/zdharma/zui
    zinit ice lucid wait'[[ -n ${ZLAST_COMMANDS[(r)cras*]} ]]'
    zinit load https://github.com/zdharma/zplugin-crasis

    zinit ice pick"async.zsh" src"pure.zsh"
    zinit load https://github.com/ahmedelgabri/pure
    local SYMBOLS=("λ" "ϟ" "▲" "∴" "→" "»" "৸" "◗")

    # Arrays in zsh starts from 1
    export PURE_PROMPT_SYMBOL="${SYMBOLS[$RANDOM % ${#SYMBOLS[@]} + 1]}"
    export PURE_GIT_UP_ARROW='🠥'
    export PURE_GIT_DOWN_ARROW='🠧'
    # Old icon 
    export PURE_GIT_BRANCH="  "
    zstyle :prompt:pure:path color 240
    zstyle :prompt:pure:git:branch color blue
    zstyle :prompt:pure:git:dirty color red
    zstyle :prompt:pure:git:action color 005
    zstyle :prompt:pure:prompt:success color 003
  # }}}

  # Utilities & enhancements {{{
    zinit ice wait lucid
    zinit load https://github.com/zsh-users/zsh-history-substring-search
    # bind UP and DOWN keys
    bindkey "${terminfo[kcuu1]}" history-substring-search-up
    bindkey "${terminfo[kcud1]}" history-substring-search-down

    # bind UP and DOWN arrow keys (compatibility fallback)
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down

    zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" atpull'%atclone' pick"clrs.zsh" nocompile'!' atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
    zinit load trapd00r/LS_COLORS
  # }}}

  # Local plugins/completions/etc... {{{
    zinit load %HOME/.config/zsh.d/aliases
  # }}}

  # Recommended be loaded last {{{
    zinit ice wait blockf lucid atpull'zinit creinstall -q .'
    zinit load https://github.com/zsh-users/zsh-completions

    zinit ice wait lucid atinit"zpcompinit; zpcdreplay" atload"unset 'FAST_HIGHLIGHT[chroma-whatis]' 'FAST_HIGHLIGHT[chroma-man]'"
    zinit load https://github.com/zdharma/fast-syntax-highlighting

    zinit ice wait lucid atload"_zsh_autosuggest_start"
    zinit load https://github.com/zsh-users/zsh-autosuggestions
    export ZSH_AUTOSUGGEST_USE_ASYNC=true
  # }}}

  ##############################################################
  # PLUGINS VARS & SETTINGS
  ##############################################################

  ############### Python
  export PYTHONSTARTUP="${HOME}/.pyrc.py"

  ############### z.sh
  [[ -f "${HOMEBREW_PREFIX}/etc/profile.d/z.sh" ]] && source "${HOMEBREW_PREFIX}/etc/profile.d/z.sh"

  ############### grc
  [[ -f "${HOMEBREW_PREFIX}/etc/grc.zsh" ]] && source "${HOMEBREW_PREFIX}/etc/grc.zsh"

  ############### FZF
  if [[ -f "${XDG_CONFIG_HOME}/fzf/fzf.zsh" ]]; then
    source "${XDG_CONFIG_HOME}/fzf/fzf.zsh"
  else
    echo "y" | "${HOMEBREW_PREFIX}/opt/fzf/install" --xdg --no-update-rc
  fi

  export VIM_FZF_LOG=$(git config --get alias.l 2>/dev/null | awk '{$1=""; print $0;}' | tr -d '\r')

  typeset -AU __FZF
  if (( $+commands[fd] )); then
    __FZF[CMD]='fd --hidden --no-ignore-vcs --exclude ".git" --exclude "node_modules" --exclude ".DS_Store"'
    __FZF[DEFAULT]="${__FZF[CMD]} --type f"
    __FZF[ALT_C]="${__FZF[CMD]} --type d ."
  elif (( $+commands[rg] )); then
    __FZF[CMD]='rg --no-messages --no-ignore-vcs'
    __FZF[DEFAULT]="${__FZF[CMD]} --files"
  else
    __FZF[DEFAULT]='git ls-tree -r --name-only HEAD || find .'
  fi

  export FZF_DEFAULT_COMMAND="${__FZF[DEFAULT]}"
  export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"
  export FZF_CTRL_T_COMMAND="${__FZF[CMD]}"
  export FZF_ALT_C_COMMAND="${__FZF[ALT_C]}"
  export FZF_DEFAULT_OPTS="--reverse --tabstop 2 --multi --color=bg+:-1 --bind '?:toggle-preview'"
  export FZF_CTRL_T_OPTS="--preview '($FZF_PREVIEW_COMMAND) 2> /dev/null' --preview-window down:60%:noborder"
  export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"
  export FZF_ALT_C_OPTS="--preview 'tree -C {} 2> /dev/null'"

  ############### Homebrew
  export HOMEBREW_INSTALL_BADGE="⚽️"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_FORCE_BREWED_GIT=1

  ############### Bat, Ripgrep, Weechat
  export BAT_CONFIG_PATH="${HOME}/.batrc"
  export RIPGREP_CONFIG_PATH="${HOME}/.rgrc"
  export WEECHAT_PASSPHRASE=`security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`

  ############### Direnv
  export N_PREFIX="${HOME}/.n"
  export NODE_VERSIONS="${N_PREFIX}/n/versions/node"
  export NODE_VERSION_PREFIX=""
  (( $+commands[direnv] )) && eval "$(direnv hook zsh)"
  (( $+commands[hub] )) && eval "$(hub alias -s)"

  ############### Kitty
  if [[ ! -z "${KITTY_WINDOW_ID}" ]]; then
    kitty + complete setup zsh | source /dev/stdin
  fi

  if [ "$(uname)" = "Darwin" ]; then
    # For context https://github.com/github/hub/pull/1962
    # I run in the background to not affect startup time.
    # https://github.com/ahmedelgabri/dotfiles/commit/c8156c2f0cf74917392a0e700668005b8f1bbbdb#r33940655
    (
      if [ -e /usr/local/share/zsh/site-functions/_git ]; then
        command mv -f /usr/local/share/zsh/site-functions/{,disabled.}_git
      fi
    ) &!
  fi

  ##############################################################
  # LOCAL.
  ##############################################################

  if [ -f ${HOME}/.zshrc.local ]; then
    source ${HOME}/.zshrc.local
  else
    [[ -z "${HOMEBREW_GITHUB_API_TOKEN}" ]] && echo "⚠ HOMEBREW_GITHUB_API_TOKEN not set." && _has_unset_config=yes
    [[ -z "${GITHUB_TOKEN}" ]] && echo "⚠ GITHUB_TOKEN not set." && _has_unset_config=yes
    [[ -z "${GITHUB_USER}" ]] && echo "⚠ GITHUB_USER not set." && _has_unset_config=yes
    [[ ${_has_unset_config:-no} == "yes" ]] && echo "Set the missing configs in ~/.zshrc"
  fi

  if [ -e /etc/motd ]; then
    if ! cmp -s ${HOME}/.hushlogin /etc/motd; then
      tee ${HOME}/.hushlogin < /etc/motd
    fi
  fi
}
