#!/bin/bash

# sitespeedio/sitespeedio
# tobli/browsertime

# Homebrew taps
TAPS=(
  caskroom/cask
  caskroom/fonts
  caskroom/versions
  homebrew/dupes
  homebrew/versions
)

# Homebrew Formulas
FORMULAS=(
  coreutils
  findutils
  zsh
  caskroom/cask/brew-cask
  wget
  z
  git
  node
  tree
  dnsmasq
  mongodb
  phantomjs
  hub
  heroku-toolbelt
  rbenv
  rbenv-gem-rehash
  ruby-build
  the_silver_searcher
  macvim --override-system-vim --custom-icons --with-lua
  weechat --with-perl --with-python --with-lua --with-curl
  imagemagick
  nginx
  mysql
  todo-txt
  ctags
  python --universal #2.7.8
  openssl
  gdal #1.11.1
  geos #3.4.2
  postgis #2.1.4
  postgresql #9.3.5
  proj #4.8.0
  homebrew/versions/elasticsearch-0.20 #0.20.6
  libmemcached #1.0.18
  redis
)

# Homebrew casks
CASKS=(
  alfred
  appcleaner
  betterzipql
  box-sync
  caffeine
  chromecast
  dash
  evernote
  firefox
  firefox-aurora
  firefox-nightly
  font-droid-sans-mono
  font-droid-sans-mono-for-powerline
  font-inconsolata
  font-inconsolata-dz-for-powerline
  font-meslo-lg
  font-meslo-lg-for-powerline
  font-source-code-pro
  hipchat
  imagealpha
  imageoptim
  iterm2
  jdownloader2
  lynxlet
  opera
  opera-beta
  qlcolorcode
  qlmarkdown
  qlprettypatch
  qlstephen
  quicklook-csv
  quicklook-json
  recordit
  sequel-pro
  sketch
  skype
  spectacle
  sublime-text3
  synergy
  teamviewer
  telegram
  the-unarchiver
  transmission
  transmit
  virtualbox
  vlc
  webkit-nightly
  webpquicklook
)

#================================================================================

brew update

brew tap ${TAPS[@]} && brew install ${FORMULAS[@]}

echo "to update setuptools & pip run: pip install --upgrade setuptools pip install --upgrade pip"
echo "Don’t forget to add $(brew --prefix coreutils)/libexec/gnubin to \$PATH."
echo " Changing shell...."
# sudo echo "/usr/local/bin/zsh" >> /etc/shells && chsh -s /usr/local/bin/zsh


brew cask install --appdir="~/Applications" ${CASKS[@]} && brew cask alfred link

# 1Password form the Apple Store needs Chrome to be in /Applications
# Known issues #3
# https://guides.agilebits.com/1password-mac-kb/5/en/topic/browser-validation-failed

echo "Install Chrome & Chrome Canary in /Applications dir"
# brew cask install --appdir="/Applications" google-chrome
# brew cask install --appdir="/Applications" google-chrome-canary


echo "Put your license in Dash & Sublime. and Install Tweetbot"

brew cleanup
