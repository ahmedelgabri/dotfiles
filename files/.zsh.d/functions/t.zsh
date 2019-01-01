# For todoist cli

# Exit if yarn is not installed
(( $+commands[todoist] )) || return 0

unalias t 2>/dev/null

function t() {
  __CMD=(todoist --color --indent --namespace --project-namespace)

  if [[ $# -eq 0 ]]; then
    __CMD+=(l)
  else
    __CMD+=($@)
  fi

  todoist sync && "${__CMD[@]}"
}

# compdef t=todoist
