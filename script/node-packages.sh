#!/bin/bash

NPM_PACKAGES=(
"jscpd"
"jsctags"
"jsinspect"
"netlify-cli"
"now"
"parker"
"prettier"
"serve"
"surge"
"svgo"
"tern"
)

yarn global add --prefix "~/.yarn" "${PACKAGES[@]}"

unset -v NPM_PACKAGES
