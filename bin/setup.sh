#!/bin/bash

function setup {
    if ! type "rvm" > /dev/null; then
        echo -e "$fg[red] Installing RVM... $reset_color"
        curl -L https://get.rvm.io | bash -s stable
    fi

    if ! type_exists "gcc"; then

        echo -e "The XCode Command Line Tools must be installed first."
        printf "  Download them from: https://developer.apple.com/downloads\n"

        if ! type "brew" > /dev/null; then
            echo -e "$fg[red] Installing Homebrew... $reset_color"
            ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"

            if ! type "git" > /dev/null; then
                echo -e "$fg[red] Installing git... $reset_color"
                brew install git
            fi
            if ! type "npm" > /dev/null; then
                echo -e "$fg[red] Installing Node... $reset_color"
                brew install node

                if ! type "grunt" > /dev/null; then
                  echo -e "$fg[red] Installing grunt-cli... $reset_color"
                  npm install -g grunt-cli
                fi
            fi

        fi
    fi
}



# installing ohmyzsh
curl -L https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh | sh

# setup
setup

# cloning my dotfiles
git clone https://github.com/ahmedelgabri/dotfiles.git $HOME/.dotfiles
cd $HOME/.dotfiles
sh install.sh

source $HOME/.zshrc && rvm reload