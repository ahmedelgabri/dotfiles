#!/bin/bash

PACKAGES=(
"--upgrade setuptools"
"--upgrade pip"
# "markdown"
"neovim"
"vim-vint"
"websocket-client"
"pipenv"
)

for package in "${PACKAGES[@]}"; do
  pip3 install --user "$package" && pip2 install --user "$package"
done

unset -v PACKAGES
