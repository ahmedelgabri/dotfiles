# My [.]files

For setting up development environment on new Mac. The config is managed by [GNU stow](https://www.gnu.org/software/stow/)

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/screenshot.gif)


## Installation

```sh
$ curl -sS https://raw.github.com/ahmedelgabri/dotfiles/master/script/install | sh
```
or

```sh
$ git clone https://github.com/ahmedelgabri/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make install
```

### After installation

Change shell to `zsh`

Add the homebrew installed zsh to /etc/shells (so that chsh will consider it a "safe" shell):

    $ echo "$(which zsh)" | sudo tee -a /etc/shells > /dev/null
    $ chsh -s "$(which zsh)" "$(whoami)"


Use [Google DNS](https://developers.google.com/speed/public-dns/)


#### Notes
 You might need to install Install Command line tools through [Xcode](https://itunes.apple.com/en/app/xcode/id497799835?mt=12) from the App Store
