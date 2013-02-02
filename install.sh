#!/bin/bash

echo "Cleaning..."

rm ~/.gitignore
rm ~/.gitconfig
rm ~/.zshrc
rm ~/.osx
sudo rm /usr/bin/subl
rm -rf ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
rm -rf ~/Library/Preferences/com.googlecode.iterm2.plist

echo "House is clean."
echo "Building..."

ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/.dotfiles/git-config/.gitignore ~/.gitignore
ln -s ~/.dotfiles/git-config/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/osx/.osx ~/.osx
sudo ln -s ~/.dotfiles/bin/subl /usr/bin/subl
ln -s ~/.dotfiles/sublimetext/User/ ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User/
ln -s ~/.dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

source ~/.zshrc

echo "Done. Wohoo!"