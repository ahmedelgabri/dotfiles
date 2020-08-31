# vim:ft=zsh:
# setopt warn_create_global

##############################################################
# Profiling.
##############################################################

# uncomment to profile & run `zprof`
# zmodload zsh/zprof

typeset -AU __FZF
typeset -g ZPLG_MOD_DEBUG=1
declare -A ZINIT

function {
  # To override Catalina /etc/zshrc
  HISTSIZE=1000000
  SAVEHIST=$HISTSIZE
  HISTFILE="${XDG_DATA_HOME:-$HOME}/.zsh_history"

  # Set neovim as EDITOR if it's available, otherwise use vim
  (( $+commands[nvim] )) && export EDITOR=nvim || export EDITOR=vim
  export VISUAL=$EDITOR
  export GIT_EDITOR=$EDITOR
  case $EDITOR in
      nvim) export MANPAGER="nvim +Man!" ;;
       vim) export MANPAGER="/bin/sh -c \"col -b | vim -c 'set ft=man' -\"" ;;
         *) export MANPAGER='less' ;;
  esac

  ##############################################################
  # ZINIT https://github.com/zdharma/zinit
  ##############################################################
  # Investigate why this doesn't work with tmux when I add it to zshenv
  ZINIT[HOME_DIR]="$XDG_CACHE_HOME/zsh/zinit"
  ZINIT[BIN_DIR]="$ZINIT[HOME_DIR]/bin"
  ZINIT[PLUGINS_DIR]="$ZINIT[HOME_DIR]/plugins"
  ZINIT[ZCOMPDUMP_PATH]="$XDG_CACHE_HOME/zsh/zcompdump"
  # export ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]=1
  export ZPFX="$ZINIT[HOME_DIR]/polaris"

  local __ZINIT="$ZINIT[BIN_DIR]/zinit.zsh"

  if [[ ! -f "$__ZINIT" ]]; then
    if (( $+commands[git] )); then
      git clone https://github.com/zdharma/zinit.git "$ZINIT[BIN_DIR]"
    else
      echo 'git not found' >&2
      exit 1
    fi
  fi

  source "$__ZINIT"
  autoload -Uz _zinit
  (( ${+_comps} )) && _comps[zinit]=_zinit

  # Shell {{{
    zinit snippet OMZP::gpg-agent

    zinit ice wait lucid from'gh-r' as'program'
    zinit light https://github.com/junegunn/fzf-bin

    zinit ice wait lucid as'command' multisrc'shell/{completion,key-bindings}.zsh' id-as'junegunn/fzf_completions' pick'bin/fzf-tmux'
    zinit light https://github.com/junegunn/fzf

    zinit ice wait lucid from'gh-r' as'program' \
      mv'zoxide* -> zoxide' atclone'echo "unalias zi 2> /dev/null " > zhook.zsh && ./zoxide init zsh --hook pwd >> zhook.zsh' atpull'%atclone' src'zhook.zsh'
    zinit light https://github.com/ajeetdsouza/zoxide

    zinit ice wait lucid as'program' \
      atclone'./install.sh $ZPFX $ZPFX && ln -sf $ZPFX/share/grc ~/.config/grc' atpull'%atclone' compile'grc.zsh' src'grc.zsh' pick'$ZPFX/bin/grc*'
    zinit light https://github.com/garabik/grc

    zinit ice pick'async.zsh' src'pure.zsh'
    zinit light https://github.com/ahmedelgabri/pure
    PURE_SYMBOLS=("λ" "ϟ" "▲" "∴" "→" "»" "৸" "◗")
    # Arrays in zsh starts from 1
    export PURE_PROMPT_SYMBOL="${PURE_SYMBOLS[$RANDOM % ${#PURE_SYMBOLS[@]} + 1]}"
    zstyle :prompt:pure:path color 240
    zstyle :prompt:pure:git:branch color blue
    zstyle :prompt:pure:git:dirty color red
    zstyle :prompt:pure:git:action color 005
    zstyle :prompt:pure:prompt:success color 003

    zinit ice wait lucid from'gh-r' as'program' \
      mv'direnv* -> direnv' atclone'./direnv hook zsh > zhook.zsh' atpull'%atclone' src'zhook.zsh'
    zinit light https://github.com/direnv/direnv

    zinit ice wait lucid from'gh-r' as'program' mv'hub* -> hub' \
      atclone'prefix=$ZPFX ./hub/install; ln -sf ./hub/etc/hub.zsh_completion _hub; ./hub/bin/hub alias -s > zhook.zsh;' \
      atpull'%atclone' src'zhook.zsh' pick'$ZPFX/bin/hub*'
    zinit light https://github.com/github/hub

  # }}}

  # Utilities & enhancements {{{
    zinit ice wait lucid
    zinit light https://github.com/zsh-users/zsh-history-substring-search
    # bind UP and DOWN keys
    bindkey "${terminfo[kcuu1]}" history-substring-search-up
    bindkey "${terminfo[kcud1]}" history-substring-search-down

    # bind UP and DOWN arrow keys (compatibility fallback)
    bindkey '^[[A' history-substring-search-up
    bindkey '^[[B' history-substring-search-down

    zinit ice atclone"dircolors -b LS_COLORS > clrs.zsh" \
      atpull'%atclone' pick"clrs.zsh" nocompile'!' atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”'
    zinit light https://github.com/trapd00r/LS_COLORS

    zinit ice wait lucid from'gh-r' as'command' pick'clojure-lsp'
    zinit light https://github.com/snoe/clojure-lsp
  # }}}

  # Local plugins/completions/etc... {{{
    zinit light %HOME/.config/zsh/aliases
  # }}}

  # Recommended be loaded last {{{
    zinit ice wait blockf lucid atpull'zinit creinstall -q .'
    zinit light https://github.com/zsh-users/zsh-completions

    zinit ice wait lucid atinit'ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay' \
      atload'unset "FAST_HIGHLIGHT[chroma-whatis]" "FAST_HIGHLIGHT[chroma-man]"'
    zinit light https://github.com/zdharma/fast-syntax-highlighting

    zinit ice wait lucid atload'_zsh_autosuggest_start'
    zinit light https://github.com/zsh-users/zsh-autosuggestions
  # }}}

  ##############################################################
  # PLUGINS VARS & SETTINGS
  ##############################################################
  ############### FZF
  export VIM_FZF_LOG=$(git config --get alias.l 2>/dev/null | awk '{$1=""; print $0;}' | tr -d '\r')

  if (( $+commands[fd] )); then
    __FZF[CMD]='fd --hidden --follow --no-ignore-vcs'
    __FZF[DEFAULT]="${__FZF[CMD]} --type f"
    __FZF[ALT_C]="${__FZF[CMD]} --type d ."
  elif (( $+commands[rg] )); then
    __FZF[CMD]='rg --follow --no-messages --no-ignore-vcs'
    __FZF[DEFAULT]="${__FZF[CMD]} --files"
  else
    __FZF[DEFAULT]='git ls-tree -r --name-only HEAD || find .'
  fi

  export FZF_DEFAULT_COMMAND="${__FZF[DEFAULT]}"
  export FZF_PREVIEW_COMMAND="bat --style=numbers,changes --wrap never --color always {} || cat {} || tree -C {}"
  export FZF_CTRL_T_COMMAND="${__FZF[CMD]}"
  export FZF_ALT_C_COMMAND="${__FZF[ALT_C]}"
  export FZF_DEFAULT_OPTS="--prompt='» ' --pointer='▶' --marker='✓ ' --reverse --tabstop 2 --multi --color=bg+:-1,marker:010 --bind '?:toggle-preview'"
  export FZF_CTRL_T_OPTS="--preview '($FZF_PREVIEW_COMMAND) 2> /dev/null' --preview-window down:60%:noborder"
  export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window down:3:wrap:hidden --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort' --header 'Press CTRL-Y to copy command into clipboard'"
  export FZF_ALT_C_OPTS="--preview 'tree -C {} 2> /dev/null'"

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
    [[ -z "${WEECHAT_PASSPHRASE}" ]] && echo "⚠ WEECHAT_PASSPHRASE not set." && _has_unset_config=yes
    [[ ${_has_unset_config:-no} == "yes" ]] && echo "Set the missing configs in ~/.zshrc.local"
  fi

  if [ -e /etc/motd ]; then
    if ! cmp -s ${HOME}/.hushlogin /etc/motd; then
      tee ${HOME}/.hushlogin < /etc/motd
    fi
  fi
}
