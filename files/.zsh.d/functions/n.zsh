# Shadow `n` https://github.com/tj/n for ease of use in repos with `.nvmrc` or `.node-version` files

unalias n 2>/dev/null

function n() {
  if [[ $# -eq 0 ]]; then
    __CMD=("${HOMEBREW_ROOT}/bin/n")
    __VERSION=""

    [[ -f ".nvmrc" ]] && __VERSION=$(command cat .nvmrc)
    [[ -f ".node-version" ]] && __VERSION=$(command cat .node-version)

    if [[ ! -z "$__VERSION" && ! -d "${N_PREFIX}/n/versions/node/${__VERSION}" ]]; then
      __CMD+=(--download $__VERSION)
    fi
  else
    __CMD+=($@)
  fi

  "${__CMD[@]}"
}

# compdef n=n
