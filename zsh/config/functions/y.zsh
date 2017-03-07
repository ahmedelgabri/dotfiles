# I'm lazy to run `yarn` & `yarn run <script>`

function y {
  if (( $+commands[yarn] )); then
    if [[ $# > 0 ]]; then
      yarn run "$@"
    else
      yarn
    fi
  else
    echo "Yarn is not in your path, make sure you install it or fix your path"
    exit 1
  fi
}
