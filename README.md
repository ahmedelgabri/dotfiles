# My [.]files

For setting up development environment on new Mac. You are welcome to give tips on how can I improve this.

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/screenshot.gif)

The config is managed by [GNU stow](https://www.gnu.org/software/stow/)

## Installation

Change shell to `zsh`

Add the homebrew installed zsh to /etc/shells (so that chsh will consider it a "safe" shell):

    $ echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null
    $ chsh -s "$(which zsh)" "$(whoami)"

Install Command line tools through [Xcode](https://itunes.apple.com/en/app/xcode/id497799835?mt=12) from the App Store

Install

    $ git clone https://github.com/ahmedelgabri/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make install

### After installation

- Use [Google DNS](https://developers.google.com/speed/public-dns/)
