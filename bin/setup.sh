#!/bin/bash

function setup {
    if ! type_exists "gcc"; then
        echo -e "The XCode Command Line Tools must be installed first."
        printf "Download them from: https://developer.apple.com/downloads or download xcode from the App Store\n"
        exit 1

        if ! type "brew" > /dev/null; then
            echo -e "$fg[red] Installing Homebrew... $reset_color\n"
            ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)\n"
            brew update
            brew install tree
            brew install ack
            brew install coreutils
            brew install wget

            if ! type "git" > /dev/null; then
                echo -e "$fg[red] Installing git... $reset_color\n"
                brew install git
                brew install tig
            fi

            if ! type "rbenv" > /dev/null; then
                echo -e "$fg[red] Installing rbenv... $reset_color\n"
                brew install rbenv
                brew install ruby-build
                brew install rbenv-gem-rehash
                source $HOME/.zshrc
                gem update --system
                # @TODO: Automate this
                # echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
                # echo -e "$fg[red]Installing gems$reset_color\n"
                # echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
                # gem install paste -d" " -s $HOME/.dotfiles/ruby/gems.txt
            fi

            if ! type "npm" > /dev/null; then
                echo -e "$fg[red] Installing Node... $reset_color\n"
                brew install node
                # @TODO: Automate this
                # echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
                # echo -e "$fg[red]Installing NPM packages$reset_color\n"
                # echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
                # npm install -g paste -d" " -s $HOME/.dotfiles/node/packages.txt

                if ! type "grunt" > /dev/null; then
                  echo -e "$fg[red] Installing grunt-cli... $reset_color\n"
                  npm install -g grunt-cli

                fi
            fi
        fi
    fi
}

echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
echo -e "$fg[red]Starting setup ......$reset_color\n"
echo -e "$fg[red]------------------------------------------------------------$reset_color\n"
setup

echo -e "$fg[green]------------------------------------------------------------$reset_color\n"
echo -e "$fg[green]reload ZSH$reset_color\n"
echo -e "$fg[green]------------------------------------------------------------$reset_color\n"
source $HOME/.zshrc