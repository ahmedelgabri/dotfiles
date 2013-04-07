#!/bin/bash

echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
echo -e "$fg[red]installing ohmyzsh$reset_color\n"
echo -e "$fg[red]------------------------------------------------------------$reset_color\n"

curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh
/bin/zsh
source $HOME/.zshrc


echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
echo -e "$fg[red]cloning dotfiles$reset_color\n"
echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
git clone https://github.com/ahmedelgabri/dotfiles.git $HOME/.dotfiles
cd $HOME/.dotfiles/bin
sh install.sh

echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
echo -e "$fg[red]Cleaning...$reset_color\n"
echo -e "$fg[red]------------------------------------------------------------$reset_color\n"

rm $HOME/.gitignore
rm $HOME/.gitconfig
rm $HOME/.zshrc
rm $HOME/.oh-my-zsh/themes/gabri-new.zsh-theme
rm $HOME/.osx
rm $HOME/.vimrc
rm $HOME/.gemrc
rm -rf $HOME/.vim


echo -e "$fg[green]------------------------------------------------------------$reset_color\n"
echo -e "$fg[green]House is clean.$reset_color\n"
echo -e "$fg[red]Building...$reset_color\n"
echo -e "$fg[red]------------------------------------------------------------$reset_color\n"

ln -s $HOME/.dotfiles/zsh/zshrc.local $HOME/.zshrc
ln -s $HOME/.dotfiles/zsh/gabri-new.zsh-theme $HOME/.oh-my-zsh/themes/gabri-new.zsh-theme
ln -s $HOME/.dotfiles/gitconfig/gitignore.local $HOME/.gitignore
ln -s $HOME/.dotfiles/gitconfig/gitconfig.local $HOME/.gitconfig
ln -s $HOME/.dotfiles/osx/osx.local $HOME/.osx
ln -s $HOME/.dotfiles/vim/vimrc.local $HOME/.vimrc
ln -s $HOME/.dotfiles/vim/config $HOME/.vim
ln -s $HOME/.dotfiles/ruby/gemrc.local $HOME/.gemrc


# source $HOME/.zshrc

echo -e "$fg[green]------------------------------------------------------------$reset_color\n"
echo -e "$fg[green]Done. Wohoo!$reset_color\n"
echo -e "$fg[green]------------------------------------------------------------$reset_color\n"
