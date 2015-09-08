# No arguments: `open .`
# With arguments: acts like `open`
o() {
  if [[ $# -eq 0 ]]; then
    open .
  else
    open $@
  fi
}

# Complete o like open
compdef o=open
