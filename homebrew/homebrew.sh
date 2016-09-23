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
brewtap "homebrew/bundle"
brewtap "homebrew/services"
brewtap "homebrew/versions"
brewtap "homebrew/dupes"
brewtap "caskroom/cask"
brewtap "caskroom/fonts"
brewtap "caskroom/versions"
brewtap "neovim/neovim"
brewtap "tldr-pages/tldr"
brewtap "universal-ctags/universal-ctags"
brewtap "neomutt/homebrew-neomutt"

# Formulas
brewinstall git
brewinstall python
brewinstall python3
brewinstall nvm
# brewinstall ledger
# brewinstall cmake
brewinstall asciinema
brewinstall awscli
brewinstall bitlbee
brewinstall caskroom/cask/brew-cask
brewinstall cloc
brewinstall coreutils
brewinstall cowsay
brewinstall curl
brewinstall diff-so-fancy
brewinstall docker
brewinstall elm
brewinstall emacs
brewinstall figlet
brewinstall findutils
brewinstall fortune
brewinstall fpp
brewinstall gawk
brewinstall ghi
brewinstall gnu-sed
brewinstall gnupg2
brewinstall gpg-agent
brewinstall grc
brewinstall heroku-toolbelt
brewinstall highlight
brewinstall htop
brewinstall httpie
brewinstall hub
brewinstall jo
brewinstall jq
brewinstall jrnl
brewinstall keybase
brewinstall links
brewinstall msmtp
brewinstall ncdu
brewinstall neomutt/neomutt/neomutt --with-sidebar-patch
brewinstall neovim --HEAD
brewinstall pinentry-mac
brewinstall ponysay
brewinstall ranger
brewinstall reattach-to-user-namespace
brewinstall ruby
brewinstall screenfetch
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
brewinstall urlview
brewinstall weechat --with-perl --with-python --with-ruby --with-lua --with-curl
brewinstall wget
brewinstall z
brewinstall zsh

# casks
brewinstall cask alfred
brewinstall cask appcleaner
brewinstall cask arq
brewinstall cask atom
brewinstall cask betterzipql
brewinstall cask box-sync
brewinstall cask charles
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
brewinstall cask font-inconsolata-dz-for-powerline
brewinstall cask font-inconsolata-dz-for-powerline
brewinstall cask font-meslo-lg-for-powerline
brewinstall cask font-meslo-lg-for-powerline
brewinstall cask font-source-code-pro
brewinstall cask font-source-code-pro
brewinstall cask google-chrome
brewinstall cask google-chrome-canary
brewinstall cask hyperterm
brewinstall cask imagealpha
brewinstall cask imageoptim
brewinstall cask iterm2-nightly
brewinstall cask keepingyouawake
brewinstall cask licecap
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
brewinstall cask whatsapp
# brewinstall cask gpgtools

#================================================================================


echo "to update setuptools & pip run: pip install --upgrade setuptools pip install --upgrade pip"
echo " Changing shell...."
# sudo echo "/usr/local/bin/zsh" >> /etc/shells && chsh -s /usr/local/bin/zsh

echo "Put your license in Dash and Install Tweetbot"

brew cleanup && brew doctor
