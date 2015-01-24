#!/bin/bash

PACKAGES=(
  --upgrade setuptools
  --upgrade pip
  numpy
  pygments
  virtualenv
  virtualenvwrapper
  markdown
)

mkdir ~/.venv
pip install ${PACKAGES[@]}
