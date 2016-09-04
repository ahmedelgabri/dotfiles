#!/usr/bin/env bash

# Check for Homebrew,
# Install if we don't have it
if ! command -v brew >/dev/null; then
  echo "\033[0;34m------------------------------------------------------------\033[0;0m"
  echo "\033[0;34m====== Installing Homebrew =================================\033[0;0m"
  echo "\033[0;34m------------------------------------------------------------\033[0;0m"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update

# functions
function brewtap() {
  if ! brew tap > /dev/null; then
    echo_title "Tap brew $1"
    brew tap "$1"
  fi
}

function brewinstall() {
  # brew install "${@}" 2>&1 | grep -v "already installed"
  if [ "$1" == "cask" ]; then
    brew "$1" install "$2" 2>&1
  else
    brew install "${@}" 2>&1
  fi
}

# Taps
brewtap caskroom/cask
brewtap caskroom/fonts
brewtap caskroom/versions
brewtap homebrew/dupes
brewtap homebrew/versions
brewtap neovim/neovim
brewtap tldr-pages/tldr
brewtap universal-ctags/universal-ctags
brewtap neomutt/homebrew-neomutt

# Formulas
brewinstall git
brewinstall diff-so-fancy
brewinstall python
brewinstall python3
brewinstall nvm
brewinstall reattach-to-user-namespace
brewinstall coreutils
brewinstall findutils
brewinstall gnu-sed
brewinstall wget
brewinstall asciinema
brewinstall awscli
brewinstall caskroom/cask/brew-cask
brewinstall cowsay
brewinstall docker
brewinstall figlet
brewinstall grc
brewinstall heroku-toolbelt
brewinstall hub
brewinstall jq
brewinstall jrnl
brewinstall keybase
# brewinstall ledger
brewinstall links
brewinstall ncdu
brewinstall neovim --HEAD
brewinstall spark
brewinstall task
brewinstall the_silver_searcher
brewinstall tidy-html5
brewinstall tig
brewinstall tldr-pages/tldr/tldr
brewinstall tmux --HEAD
brewinstall todo-txt
brewinstall tree
brewinstall unar
brewinstall universal-ctags/universal-ctags/universal-ctags
brewinstall weechat --with-perl --with-python --with-ruby --with-lua --with-curl
brewinstall z
brewinstall zsh
brewinstall bitlbee
brewinstall curl
brewinstall httpie
brewinstall elm
brewinstall gnupg
brewinstall gpg-agent
brewinstall pinentry-mac
brewinstall ansiweather
brewinstall asciidoc
brewinstall cloc
brewinstall fortune
brewinstall fpp
brewinstall gawk
brewinstall ghi
brewinstall highlight
brewinstall jo
brewinstall ponysay
brewinstall ranger
brewinstall ruby
brewinstall screenfetch
brewinstall neomutt/neomutt/neomutt --with-sidebar-patch
brewinstall urlview
brewinstall msmtp

# casks
brewinstall cask alfred
brewinstall cask appcleaner
brewinstall cask arq
brewinstall cask atom
brewinstall cask betterzipql
brewinstall cask box-sync
brewinstall cask dayone-cli
brewinstall cask firefox
brewinstall cask firefox-beta
brewinstall cask firefoxdeveloperedition
brewinstall cask firefoxnightly
brewinstall cask flux
brewinstall cask font-anka-coder
brewinstall cask font-droid-sans-mono-for-powerline
brewinstall cask font-fira-code
brewinstall cask font-fira-mono-for-powerline
brewinstall cask font-hack
brewinstall cask font-inconsolata-dz-for-powerline
brewinstall cask font-meslo-lg-for-powerline
brewinstall cask font-source-code-pro
brewinstall cask google-chrome
brewinstall cask google-chrome-canary
brewinstall cask imagealpha
brewinstall cask imageoptim
brewinstall cask iterm2-nightly
brewinstall cask keepingyouawake
brewinstall cask opera
brewinstall cask opera-beta
brewinstall cask opera-developer
brewinstall cask qlcolorcode
brewinstall cask qlimagesize
brewinstall cask qlmarkdown
brewinstall cask qlprettypatch
brewinstall cask qlstephen
brewinstall cask qlvideo
brewinstall cask quicklook-csv
brewinstall cask quicklook-json
brewinstall cask sequel-pro
brewinstall cask sketch
brewinstall cask sketch-toolbox
brewinstall cask skype
brewinstall cask spectacle
brewinstall cask teamviewer
brewinstall cask telegram
brewinstall cask transmission
brewinstall cask transmit
brewinstall cask vagrant
brewinstall cask virtualbox
brewinstall cask visual-studio-code
brewinstall cask vlc
brewinstall cask webkit-nightly
brewinstall cask webpquicklook
# brewinstall cask gpgtools

#================================================================================


echo "to update setuptools & pip run: pip install --upgrade setuptools pip install --upgrade pip"
echo " Changing shell...."
# sudo echo "/usr/local/bin/zsh" >> /etc/shells && chsh -s /usr/local/bin/zsh

echo "Put your license in Dash and Install Tweetbot"

brew cleanup && brew doctor
