# Better C-r with atuin history database but with better fuzzy search using fzf
# Ref: https://github.com/atuinsh/atuin/issues/68#issuecomment-1567410629 with some modifications
if which atuin &>/dev/null; then
  fzf-atuin-history-widget() {
    local selected
    setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null

    local atuin_opts="--print0 --format '{relativetime}\\t{directory}\\t{command}'"
    local fzf_opts=(
      "--height=${FZF_TMUX_HEIGHT:-80%}"
      "--tac"
      $'--delimiter=\t'
      "--with-nth=3.."
      "--accept-nth=3.."
      "--scheme=history"
      "--preview=printf '%s\\n' {3..}"
      "--preview-window=next:3:hidden:wrap"
      "--bind=?:toggle-preview"
      "--query=${LBUFFER}"
      "--no-multi"
      "--highlight-line"
      "--read0"
      "--id-nth=3.."
      "--header=CTRL-D directory · CTRL-R all · CTRL-Y copy · ALT-M metadata"
      "--bind=alt-m:change-with-nth(3..|1..),ctrl-y:execute-silent(printf '%s' {3..} | pbcopy)+abort"
      "--bind=ctrl-d:reload(atuin search $atuin_opts -c ${(q)PWD}),ctrl-r:reload(atuin search $atuin_opts)"
    )

    if [[ -n ${TMUX-} ]]; then
      fzf_opts+=("--popup=center,80%,80%" "--border=none")
    fi

    selected=$(eval "atuin search ${atuin_opts}" | fzf "${fzf_opts[@]}")

    local ret=$?
    if [ -n "$selected" ]; then
      LBUFFER="${selected}"
    fi

    zle reset-prompt
    return $ret
  }

  zle -N fzf-atuin-history-widget
  bindkey '^R' fzf-atuin-history-widget
fi

# zoxide with fuzzy search
# https://github.com/ajeetdsouza/zoxide/issues/34#issuecomment-2099442403
zf() {
  local selected
  local fzf_opts=(
    "--height=40%"
    "--layout=reverse"
    "--info=inline"
    "--scheme=path"
    "--nth=2.."
    "--accept-nth=2.."
    "--preview=eza --all --group-directories-first --header --long --no-user --no-permissions --color=always {2..}"
    "--no-sort"
    "--no-multi"
  )

  if [[ -n ${TMUX-} ]]; then
    fzf_opts+=("--popup=center,70%,70%" "--border=none")
  fi

  selected=$(zoxide query --list --score | fzf "${fzf_opts[@]}") || return
  [[ -n $selected ]] && builtin cd -- "$selected"
}

# Avoid ssh issues with ssh and terminfo with new terminal apps
[[ $TERM == "xterm-kitty" ]] || [[ $TERM == "xterm-ghostty" ]] && alias ssh="TERM=xterm-256color ssh"
