#!/bin/bash

# Install apps
brew tap phinze/homebrew-cask
brew install brew-cask

function installcask() {
    brew cask install --appdir="~/Applications" "${@}" 2> /dev/null
}

installcask dropbox
installcask google-chrome
installcask google-chrome-canary
installcask firefox
installcask firefox-aurora
installcask opera
installcask opera-next
installcask caffeine
installcask alfred
# installcask cloudapp
installcask dash
installcask spectacle
installcask imagealpha
installcask imageoptim
installcask iterm2
installcask macvim
installcask sequel-pro
installcask sublime-text-3
installcask the-unarchiver
installcask sketch
installcask skype
installcask wunderlist
installcask lime-chat
installcask transmit
installcask virtualbox
installcask vlc
echo "Put your license in Dash & Sublime. and Install Tweetbot & AppCleaner"