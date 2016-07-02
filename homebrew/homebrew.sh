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
  elm
  gnupg
  gpg-agent
  pinentry-mac
  ansiweather
  asciidoc
  cloc
  fortune
  fpp
  gawk
  ghi
  highlight
  jo
  ponysay
  ranger
  ruby
  screenfetch
)

# Homebrew casks
CASKS=(
  alfred
  appcleaner
  arq
  atom
  betterzipql
  box-sync
  dayone-cli
  firefox
  firefox-beta
  firefoxdeveloperedition
  firefoxnightly
  flux
  font-anka-coder
  font-droid-sans-mono-for-powerline
  font-fira-code
  font-fira-mono-for-powerline
  font-hack
  font-inconsolata-dz-for-powerline
  font-meslo-lg-for-powerline
  font-source-code-pro
  google-chrome
  google-chrome-canary
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
  teamviewer
  telegram
  transmission
  transmit
  vagrant
  virtualbox
  visual-studio-code
  vlc
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

brew cask install ${CASKS[@]}

echo "Put your license in Dash and Install Tweetbot"

brew cleanup
