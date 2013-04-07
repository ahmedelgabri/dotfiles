#!/bin/bash
rm -rf $HOME/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
ln -s $HOME/.dotfiles/sublimetext/User $HOME/Library/Application\ Support/Sublime\ Text\ 2/Packages/User
sudo rm /usr/bin/subl
sudo ln -s $HOME/.dotfiles/sublimetext/subl.local /usr/bin/subl