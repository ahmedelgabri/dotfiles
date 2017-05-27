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
  jedi
)

mkdir ~/.venv && pip install ${PACKAGES[@]} && pip3 install ${PACKAGES[@]}
