# No arguments: `open .`
# With arguments: acts like `open`

unalias o # Prezto has it's own o alias

function o {
  if [[ $# -eq 0 ]]; then
    open .
  else
    open "$@"
  fi
}

# Complete o like open
compdef o=open
