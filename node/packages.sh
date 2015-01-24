#!/bin/bash

PACKAGES=(
  bower
  eslint
  finch
  grunt-cli
  gulp
  harp
  jscs
  jsfmt
  jshint
  jspm
  keybase
  keybase-installer
  ngrok
  node-sass
  nodemon
  stylus
)

npm i -g ${PACKAGES[@]}
