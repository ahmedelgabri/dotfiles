#!/bin/bash
rm -rf $HOME/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
ln -s $HOME/.dotfiles/sublimetext/User $HOME/Library/Application\ Support/Sublime\ Text\ 3/Packages/User
sudo rm /usr/bin/subl
sudo ln -s /Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl /usr/bin/subl