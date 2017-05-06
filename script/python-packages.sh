#!/bin/bash

PACKAGES=(
  --upgrade setuptools
  --upgrade pip
  numpy
  pygments
  virtualenv
  virtualenvwrapper
  markdown
  neovim
  vim-vint
)

mkdir ~/.venv && pip install ${PACKAGES[@]}
