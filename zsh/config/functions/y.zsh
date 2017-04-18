# I'm lazy to type `yarn`, `yarn run <script>`, etc...

if (( $+commands[yarn] )); then
  compdef y=yarn
fi

function y {
if (( $+commands[yarn] )); then
  if [[ $# > 0 ]]; then
    yarn "$@"
  else
    yarn
  fi
else
  echo "Yarn is not in your path, make sure you install it or fix your path"
  exit 1
fi
}
