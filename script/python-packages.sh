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
)

mkdir ~/.venv && pip install ${PACKAGES[@]}
