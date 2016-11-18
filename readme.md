# My [.]files

For setting up development environment on new Mac. You are welcome to give tips on how can I improve this.

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/screenshot.gif)

## Installation

Change shell to `zsh`

Add the homebrew installed zsh to /etc/shells (so that chsh will consider it a "safe" shell):

    $ echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null
    $ chsh -s "$(which zsh)" "$(whoami)"

Install Command line tools through [Xcode](https://itunes.apple.com/en/app/xcode/id497799835?mt=12) from the App Store

Install

    $ curl -sS https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/script/install | sh
