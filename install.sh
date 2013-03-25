#!/bin/bash
echo -e "Cleaning..."

rm $HOME/.gitignore
rm $HOME/.gitconfig
rm $HOME/.zshrc
rm $HOME/.oh-my-zsh/themes/gabri-new.zsh-theme
rm $HOME/.osx
rm $HOME/.vimrc
rm -rf $HOME/.vim
rm -rf $HOME/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
rm -rf $HOME/Library/Preferences/com.googlecode.iterm2.plist

echo -e "House is clean."
echo -e "Building..."

ln -s $HOME/.dotfiles/zsh/zshrc.local $HOME/.zshrc
ln -s $HOME/.dotfiles/zsh/gabri-new.zsh-theme $HOME/.oh-my-zsh/themes/gabri-new.zsh-theme
ln -s $HOME/.dotfiles/gitconfig/gitignore.local $HOME/.gitignore
ln -s $HOME/.dotfiles/gitconfig/gitconfig.local $HOME/.gitconfig
ln -s $HOME/.dotfiles/osx/osx.local $HOME/.osx
ln -s $HOME/.dotfiles/vim/vimrc.local $HOME/.vimrc
ln -s $HOME/.dotfiles/vim/config $HOME/.vim
ln -s $HOME/.dotfiles/sublimetext/User $HOME/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
ln -s $HOME/.dotfiles/iterm2/com.googlecode.iterm2.plist $HOME/Library/Preferences/com.googlecode.iterm2.plist

sudo rm /usr/bin/subl
sudo ln -s $HOME/.dotfiles/bin/subl.local /usr/bin/subl

# source $HOME/.zshrc

echo -e "Done. Wohoo!"