#!/bin/bash
# TODO: Make it more automated & add check for (zsh, git, homebrew, RVM, etc...)
echo "Cleaning..."

rm ~/.gitignore
rm ~/.gitconfig
rm ~/.zshrc
rm ~/.oh-my-zsh/themes/gabri-new.zsh-theme
rm ~/.osx
rm ~/.vimrc
rm -rf ~/.vim
rm -rf ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
rm -rf ~/Library/Preferences/com.googlecode.iterm2.plist

echo "House is clean."
echo "Building..."

ln -s ~/.dotfiles/zsh/zshrc.local ~/.zshrc
ln -s ~/.dotfiles/zsh/gabri-new.zsh-theme ~/.oh-my-zsh/themes/gabri-new.zsh-theme
ln -s ~/.dotfiles/gitconfig/gitignore.local ~/.gitignore
ln -s ~/.dotfiles/gitconfig/gitconfig.local ~/.gitconfig
ln -s ~/.dotfiles/osx/osx.local ~/.osx
ln -s ~/.dotfiles/vim/vimrc.local ~/.vimrc
ln -s ~/.dotfiles/vim/config ~/.vim
ln -s ~/.dotfiles/sublimetext/User ~/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
ln -s ~/.dotfiles/iterm2/com.googlecode.iterm2.plist ~/Library/Preferences/com.googlecode.iterm2.plist

sudo rm /usr/bin/subl
sudo ln -s ~/.dotfiles/bin/subl.local /usr/bin/subl

# source ~/.zshrc

echo "Done. Wohoo!"