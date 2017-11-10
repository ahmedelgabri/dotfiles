#!/bin/bash

NPM_PACKAGES=(
"jscpd"
"jsctags"
"jsinspect"
"javascript-typescript-langserver"
"vscode-css-languageserver-bin"
"vscode-html-languageserver-bin"
"ocaml-language-server"
"netlify-cli"
"now"
"parker"
"prettier"
"serve"
"source-map-explorer"
"surge"
"svgo"
"tern"
)

for package in "${NPM_PACKAGES[@]}"; do
  yarn global add --prefix "~/.yarn" "$package"
done


unset -v NPM_PACKAGES
