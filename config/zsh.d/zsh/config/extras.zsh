# One fzf picker over shell history and the agent history written by
# agent-history (config/zsh.d/zsh/bin). fzf's own history widget knows a
# single source, so this borrows its lossless approach instead: rows are
# "id\ttime\tdir\tcmd", and a shell row is resolved from $history[id] on
# accept because `fc -l` renders a real newline and a literal "\n" the same
# way. Agent rows carry an empty id and are used verbatim.
#
# Shell rows come from the interactive shell, but reload binds run in a
# subprocess, so they go to a temp file once and CTRL-R reloads from there.
fzf-history-rows() {
  fc -rl -t '%Y-%m-%d %H:%M' 1 |
    awk '{
      sub(/^[ \t]+/, "")
      id = $1
      sub(/\*$/, "", id)
      time = $2 " " $3
      sub(/^[^ \t]+[ \t]+[^ \t]+[ \t]+[^ \t]+[ \t]+/, "")
      print id "\t" time "\t\t" $0
    }' | tr '\n' '\0'
}

# Prints the command a selected row stands for.
fzf-history-command() {
  local row=$1 id rest
  id=${row%%$'\t'*}
  rest=${row#*$'\t'}
  rest=${rest#*$'\t'}
  rest=${rest#*$'\t'}
  if [[ -n $id ]]; then
    print -rn -- "${history[$id]}"
  else
    print -rn -- "$rest"
  fi
}

fzf-history-widget() {
  local selected tmp
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2>/dev/null
  zmodload -F zsh/parameter p:history 2>/dev/null || return 1

  tmp=$(mktemp "${TMPDIR:-/tmp}/fzf-history.XXXXXX") || return 1
  {
    # >| because NO_CLOBBER is set and mktemp already created the file.
    fzf-history-rows >|"$tmp"

    local fzf_opts=(
      "--height=${FZF_TMUX_HEIGHT:-80%}"
      $'--delimiter=\t'
      "--with-nth=4.."
      "--scheme=history"
      "--preview=printf '%s\\n' {4..}"
      "--preview-window=next:3:hidden:wrap"
      "--bind=?:toggle-preview"
      "--query=${LBUFFER}"
      "--no-multi"
      "--highlight-line"
      "--read0"
      "--print0"
      "--id-nth=4.."
      "--header=CTRL-R shell · CTRL-A agents · CTRL-D agents here · CTRL-Y copy · ALT-M metadata"
      "--bind=alt-m:change-with-nth(4..|2..),ctrl-y:execute-silent(printf '%s' {4..} | pbcopy)+abort"
      "--bind=ctrl-r:reload(cat ${(q)tmp}),ctrl-a:reload(agent-history list),ctrl-d:reload(agent-history list --dir ${(q)PWD})"
    )

    if [[ -n ${TMUX-} ]]; then
      fzf_opts+=("--popup=center,80%,80%" "--border=none")
    fi

    # fzf must run in the foreground to own the terminal, so $(...) it is;
    # the sentinel keeps trailing newlines that $(...) would strip.
    selected=$(fzf "${fzf_opts[@]}" <"$tmp"; print -n .)
    selected=${selected%.}
    selected=${selected%$'\0'}
  } always {
    rm -f "$tmp"
  }

  if [[ -n $selected ]]; then
    LBUFFER=$(fzf-history-command "$selected"; print -n .)
    LBUFFER=${LBUFFER%.}
  fi

  zle reset-prompt
  return 0
}

zle -N fzf-history-widget
bindkey '^R' fzf-history-widget

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

# Record the exact foreground command for mx --export. tmux only knows the
# process name, and process inspection loses shell syntax and builtins.
if [[ -n ${TMUX_PANE-} ]]; then
  autoload -Uz add-zsh-hook

  _mx_clear_command() {
    command tmux set-option -pqu -t "$TMUX_PANE" @mx_command 2>/dev/null || true
  }

  _mx_record_command() {
    _mx_clear_command
    # Match HIST_IGNORE_SPACE so commands deliberately omitted from history
    # are also omitted from exported session definitions.
    [[ $1 == ' '* ]] || command tmux set-option -pq -t "$TMUX_PANE" @mx_command "$1" 2>/dev/null || true
  }

  add-zsh-hook preexec _mx_record_command
  add-zsh-hook precmd _mx_clear_command
fi

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
