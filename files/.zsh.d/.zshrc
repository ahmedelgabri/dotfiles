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

  ##############################################################
  # ZPLUGIN https://github.com/zdharma/zplugin
  ##############################################################

  local __ZPLUGIN="${ZDOTDIR:-$HOME}/.zplugin/bin/zplugin.zsh"

  if [[ ! -f "$__ZPLUGIN" ]]; then
    if (( $+commands[curl] )); then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma/zplugin/master/doc/install.sh)"
    else
      echo 'curl not found' >&2
      exit 1
    fi
  fi

  source "$__ZPLUGIN"
  autoload -Uz _zplugin
  (( ${+_comps} )) && _comps[zplugin]=_zplugin

  # Shell {{{
    zplugin snippet OMZ::plugins/gpg-agent/gpg-agent.plugin.zsh

    zplugin light zdharma/zui
    zplugin ice lucid wait'[[ -n ${ZLAST_COMMANDS[(r)cras*]} ]]'
    zplugin light https://github.com/zdharma/zplugin-crasis

    zplugin ice pick"async.zsh" src"pure.zsh"
    zplugin light https://github.com/ahmedelgabri/pure
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
    zplugin ice wait lucid
    zplugin light https://github.com/zsh-users/zsh-history-substring-search
    # bind UP and DOWN keys
    bindkey "${terminfo[kcuu1]}" history-substring-search-up
    bindkey "${terminfo[kcud1]}" history-substring-search-down

    # bind UP and DOWN arrow keys (compatibility fallback)
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down


    zplugin ice wait blockf lucid
    zplugin light https://github.com/zsh-users/zsh-completions

    zplugin ice wait lucid atload"_zsh_autosuggest_start"
    zplugin light https://github.com/zsh-users/zsh-autosuggestions
    export ZSH_AUTOSUGGEST_USE_ASYNC=true

    zplugin ice wait lucid atinit"zpcompinit; zpcdreplay"
    zplugin light https://github.com/zdharma/fast-syntax-highlighting

    zplugin ice wait lucid atclone"dircolors -b LS_COLORS > c.zsh" atpull'%atclone' pick"c.zsh"
    zplugin light https://github.com/trapd00r/LS_COLORS
  # }}}

  # Misc {{{
    zplugin ice from"gh-r" as"program" bpick"*clojure-lsp*" atclone"chmod 755 clojure-lsp" atpull"%atclone" mv="clojure-lsp -> clojure-lsp"
    zplugin light https://github.com/snoe/clojure-lsp
  # }}}

  # Local plugins/completions/etc... {{{
    zplugin light %HOME/.zsh.d/aliases
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
    __FZF[CMD]='fd --hidden --no-ignore-vcs --exclude ".git" --exclude "node_modules"'
    __FZF[DEFAULT]="${__FZF[CMD]} --type f"
    __FZF[ALT_C]="${__FZF[CMD]} --type d ."
  elif (( $+commands[rg] )); then
    __FZF[CMD]='rg --no-messages --no-ignore-vcs'
    __FZF[DEFAULT]="${__FZF[CMD]} --files"
  else
    __FZF[DEFAULT]='git ls-tree -r --name-only HEAD || find .'
  fi

  export FZF_DEFAULT_COMMAND="${__FZF[DEFAULT]}"
  export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || highlight -O ansi -l {} || cat {} || tree -C {}"
  export FZF_CTRL_T_COMMAND="${__FZF[CMD]}"
  export FZF_ALT_C_COMMAND="${__FZF[ALT_C]}"
  export FZF_DEFAULT_OPTS="--reverse --tabstop 2 --multi --bind '?:toggle-preview'"
  export FZF_CTRL_T_OPTS="--min-height 30 --preview-window down:60% --preview '($FZF_PREVIEW_COMMAND) 2> /dev/null | head -500'"
  export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:hidden:wrap --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard' --border"
  export FZF_ALT_C_OPTS="--preview 'tree -C {} 2> /dev/null | head -200'"

  ############### Homebrew
  export HOMEBREW_INSTALL_BADGE="⚽️"
  export HOMEBREW_NO_ANALYTICS=1
  export HOMEBREW_FORCE_BREWED_GIT=1

  ############### Bat, Ripgrep, Weechat
  export BAT_CONFIG_PATH="${HOME}/.batrc"
  export RIPGREP_CONFIG_PATH="${HOME}/.rgrc"
  export WEECHAT_PASSPHRASE=`security find-generic-password -g -a weechat 2>&1| perl -e 'if (<STDIN> =~ m/password: \"(.*)\"$/ ) { print $1; }'`

  ############### Exa
  # di directories
  # ex executable files
  # fi regular files
  # ln symlinks
  # ur,uw,ux user permissions
  # gr,gw,gx group permissions
  # tr,tw,tx others permissions
  # sn the numbers of a file's size
  # sb the units of a file's size
  # uu user that is you
  # un user that is someone else
  # gu a group that you belong to
  # gn a group you aren't a member of
  # ga new file in Git
  # gm a modified file in Git
  # gd a deleted file in Git
  # gv a renamed file in Git
  # da a file's date
  export EXA_COLORS="uu=38;5;249:un=38;5;241:gu=38;5;245:gn=38;5;241:da=38;5;245:sn=38;5;7:sb=38;5;7:ur=38;5;3;1:uw=38;5;5;1:ux=38;5;1;1:ue=38;5;1;1:gr=38;5;3:gw=38;5;5:gx=38;5;1:tr=38;5;3:tw=38;5;1:tx=38;5;1:di=38;5;12:ex=38;5;7;1:*.md=38;5;229;4:*.png=38;5;208:*.jpg=38;5;208:*.gif=38;5;208"

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
    if [[ -z "${HOMEBREW_GITHUB_API_TOKEN}" && -z "${GITHUB_TOKEN}" && -z "${GITHUB_USER}" ]]; then
      echo "These ENV vars are not set: HOMEBREW_GITHUB_API_TOKEN, GITHUB_TOKEN & GITHUB_USER. Add them to ~/.zshrc.local"
    fi
  fi

  if [ -e /etc/motd ]; then
    if ! cmp -s ${HOME}/.hushlogin /etc/motd; then
      tee ${HOME}/.hushlogin < /etc/motd
    fi
  fi
}
