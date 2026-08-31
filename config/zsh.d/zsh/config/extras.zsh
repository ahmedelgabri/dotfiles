# Use fzf for Atuin history so one picker can search shell and agent commands.
# Ref: https://docs.atuin.sh/latest/guide/agent-hooks/
if (( $+commands[atuin] )); then
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
      "--header=CTRL-D directory · CTRL-R all · CTRL-A agents · CTRL-U user · CTRL-Y copy · ALT-M metadata"
      "--bind=alt-m:change-with-nth(3..|1..),ctrl-y:execute-silent(printf '%s' {3..} | pbcopy)+abort"
      "--bind=ctrl-d:reload(atuin search $atuin_opts -c ${(q)PWD}),ctrl-r:reload(atuin search $atuin_opts),ctrl-a:reload(atuin search $atuin_opts --author '\$all-agent'),ctrl-u:reload(atuin search $atuin_opts --author '\$all-user')"
    )

    if [[ -n ${TMUX-} ]]; then
      fzf_opts+=("--popup=center,80%,80%" "--border=none")
    fi

    selected=$(eval "atuin search ${atuin_opts}" | fzf "${fzf_opts[@]}")

    local ret=$?
    if [[ -n $selected ]]; then
      LBUFFER=$selected
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

# Project/session picker. Runs mx --pick as a real command via accept-line
# instead of inside the widget: outside tmux, mx ends in `tmux attach`,
# which must own the terminal — zle holds it while a widget runs.
if which mx &>/dev/null; then
  fzf-mx-pick-widget() {
    zle push-input
    BUFFER="mx --pick"
    zle accept-line
  }
  zle -N fzf-mx-pick-widget
  bindkey '^G' fzf-mx-pick-widget
fi

# Only exit if we're not on the last pane/window of a tmux session; detach
# instead so the session survives. Defined as a function so it can actually
# override the shell builtin.
# https://github.com/fatih/dotfiles/blob/706e1d26a1b8526755bee92c8093ab61be077894/zshrc#L238-L254
exit() {
  if [[ -z ${TMUX-} ]]; then
    builtin exit
    return
  fi

  local panes wins count
  panes=$(tmux list-panes | wc -l)
  wins=$(tmux list-windows | wc -l)
  count=$((panes + wins - 1))

  if [[ $count -eq 1 ]]; then
    tmux detach
  else
    builtin exit
  fi
}

# Let Kitty provision its remote integration; keep the compatibility fallback for Ghostty.
if [[ $TERM == "xterm-kitty" ]]; then
  alias ssh="kitten ssh"
else
  alias ssh="TERM=xterm-256color ssh"
fi
