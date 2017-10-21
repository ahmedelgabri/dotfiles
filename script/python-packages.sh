#!/bin/bash

PACKAGES=(
"--upgrade setuptools"
"--upgrade pip"
# "numpy"
# "pygments"
# "virtualenv"
# "virtualenvwrapper"
# "markdown"
"neovim"
"vim-vint"
"websocket-client"
)

# mkdir ~/.venv 

for package in "${PACKAGES[@]}"; do
  pip3 install "$package" && pip2 install "$package"
done

unset -v PACKAGES
