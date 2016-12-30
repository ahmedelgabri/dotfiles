# From https://github.com/docwhat/dotfiles/blob/6af72879803d128de980ec1f09319564aa898290/zsh/startup/iterm.zsh
# about https://github.com/tmux/tmux/issues/482
if [ "$TERM_PROGRAM" = 'iTerm.app' ]; then
  iterm-emit() {
    local template="\e]${1}\007"
    shift

    if [[ -n "$TMUX" || "$TERM" = tmux* ]]; then
      template="\ePtmux;\e${template}\e\\"
    fi
    printf "$template" "$@"
  }

  iterm-profile() {
    iterm-emit '1337;SetProfile=%s' "$1"
  }

  iterm-user-var() {
    iterm-emit '1337;SetUserVar=%s=%s' "$1" "$(echo -n "$2" | base64)"
  }

  iterm-badge-format() {
    iterm-emit '1337;SetBadgeFormat=%s' "$(echo -n "$1" | base64)"
  }

  iterm-highlight-cursor() {
    local bool="${1:-true}"
    iterm-emit '1337;HighlightCursorLine=%s' "$bool"
  }

  iterm-annotation() {
    if [ -z "$TMUX" ]; then
      # Doesn't work in TMUX
      iterm-emit '1337;AddAnnotation=%s' "${1:-annotation}"
    fi
  }

  iterm-clear-scrollback() {
    iterm-emit '1337;ClearScrollback'
  }

  iterm-get-attention() {
    iterm-emit '1337;RequestAttention=true'
  }

  iterm-steal-focus() {
    iterm-emit '1337;StealFocus'
  }

  iterm-send-cwd() {
    local cwd="${1:-$PWD}"
    iterm-emit '1337;CurrentDir=%s' "$cwd"
  }

  [[ -z $chpwd_functions ]] && chpwd_functions=()
  chpwd_functions=($chpwd_functions iterm-send-cwd)
fi
