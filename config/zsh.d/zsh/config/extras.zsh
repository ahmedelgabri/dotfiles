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

# Avoid ssh issues with ssh and terminfo with new terminal apps
[[ $TERM == "xterm-kitty" ]] || [[ $TERM == "xterm-ghostty" ]] && alias ssh="TERM=xterm-256color ssh"
