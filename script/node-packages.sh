#!/bin/bash

NPM_PACKAGES=(
"create-react-app"
"jscpd"
"jsinspect"
"netlify-cli"
"now"
"npx"
"parker"
"serve"
"spoof"
"stylefmt"
"surge"
"svgo"
"tern"
"tslide"
)

npm i -g "${PACKAGES[@]}"

unset -v NPM_PACKAGES
