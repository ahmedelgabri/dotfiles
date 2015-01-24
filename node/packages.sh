#!/bin/bash

PACKAGES=(
  analyze-css
  bower
  colorguard
  csslint
  eslint
  express
  finch
  grunt-cli
  gulp
  harp
  jscs
  jsfmt
  jshint
  jspm
  nodemon
  stylus
  node-sass
  svgo
  webpack
  browserify
)

npm i -g ${PACKAGES[@]}
