#!/bin/bash

# Check for Homebrew,
# Install if we don't have it
if ! command -v brew >/dev/null; then
  echo "\033[0;34m------------------------------------------------------------\033[0;0m"
  echo "\033[0;34m====== Installing Homebrew =================================\033[0;0m"
  echo "\033[0;34m------------------------------------------------------------\033[0;0m"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Homebrew taps
TAPS=(
  caskroom/cask
  caskroom/fonts
  caskroom/versions
  homebrew/dupes
  homebrew/versions
  neovim/neovim
  tldr-pages/tldr
  universal-ctags/universal-ctags
)

# Homebrew Formulas
FORMULAS=(
  git
  python
  python3
  nvm
  reattach-to-user-namespace
  coreutils
  findutils
  gnu-sed
  wget
  asciinema
  awscli
  caskroom/cask/brew-cask
  cowsay
  docker
  figlet
  grc
  heroku-toolbelt
  hub
  jq
  jrnl
  keybase
  # ledger
  lynx
  ncdu
  neovim --HEAD
  spark
  task
  the_silver_searcher
  tidy-html5
  tig
  tldr-pages/tldr/tldr
  tmux --HEAD
  todo-txt
  tree
  unar
  universal-ctags/universal-ctags/universal-ctags
  weechat --with-perl --with-python --with-lua --with-curl
  z
  zsh
  bitlbee
  curl
  httpie
  tidy-html5
  elm
)

# Homebrew casks
CASKS=(
  alfred
  arq
  appcleaner
  betterzipql
  box-sync
  dayone-cli
  firefox
  firefox-beta
  firefoxnightly
  firefoxdeveloperedition
  flux
  font-anka-coder
  font-droid-sans-mono-for-powerline
  font-fira-code
  font-fira-mono-for-powerline
  font-inconsolata-dz-for-powerline
  font-meslo-lg-for-powerline
  font-source-code-pro
  imagealpha
  imageoptim
  iterm2-nightly
  keepingyouawake
  opera
  opera-beta
  opera-developer
  qlcolorcode
  qlimagesize
  qlmarkdown
  qlprettypatch
  qlstephen
  qlvideo
  quicklook-csv
  quicklook-json
  sequel-pro
  sketch
  sketch-toolbox
  skype
  spectacle
  sublime-text-dev
  teamviewer
  telegram
  transmission
  transmit
  vagrant
  virtualbox
  webkit-nightly
  webpquicklook
)

#================================================================================

brew update

for tap in ${TAPS[@]}; do
  brew tap $tap
done

brew install ${FORMULAS[@]}

echo "to update setuptools & pip run: pip install --upgrade setuptools pip install --upgrade pip"
echo "Don’t forget to add $(brew --prefix coreutils)/libexec/gnubin to \$PATH."
echo " Changing shell...."
# sudo echo "/usr/local/bin/zsh" >> /etc/shells && chsh -s /usr/local/bin/zsh


brew cask install --appdir="$HOME/Applications" ${CASKS[@]} && brew cask alfred link

# 1Password form the Apple Store needs Chrome to be in /Applications
# Known issues #3
# https://guides.agilebits.com/1password-mac-kb/5/en/topic/browser-validation-failed

echo "Install Chrome & Chrome Canary in /Applications dir"
# brew cask install --appdir="/Applications" google-chrome
# brew cask install --appdir="/Applications" google-chrome-canary


echo "Put your license in Dash & Sublime. and Install Tweetbot"

brew cleanup
