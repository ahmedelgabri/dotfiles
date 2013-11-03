#!/bin/bash

# Make sure we’re using the latest Homebrew
brew update

# Upgrade any already-installed formulae
brew upgrade

# Install GNU core utilities (those that come with OS X are outdated)
brew install coreutils
echo "Don’t forget to add $(brew --prefix coreutils)/libexec/gnubin to \$PATH."
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
# brew install findutils
# Install ZSH 5
brew install zsh
echo "You need to sudo vim /etc/shells & add this /usr/local/bin/zsh to the end of the file. then run chsh -s /usr/local/bin/zsh"

brew install wget
brew install ack
brew install git
brew install node
brew install tree
brew install dnsmasq
brew install mongodb
brew install phantomjs
brew install rbenv
brew install rbenv-gem-rehash
brew install reattach-to-user-namespace
brew install ruby-build
brew install tmux
brew install the_silver_searcher
# brew install webkit2png
# brew install imagemagick

# Remove outdated versions from the cellar
brew cleanup