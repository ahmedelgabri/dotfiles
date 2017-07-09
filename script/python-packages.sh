#!/bin/bash

PACKAGES=(
"--upgrade setuptools"
"--upgrade pip"
"numpy"
"pygments"
"virtualenv"
"virtualenvwrapper"
"markdown"
"neovim"
"vim-vint"
"jedi"
"jupyter"
)

mkdir ~/.venv && pip3 install "${PACKAGES[@]}" && pip install "${PACKAGES[@]}"

unset -v PACKAGES
