# My [.]files

For setting up development environment on new Mac. The config is managed by [GNU stow](https://www.gnu.org/software/stow/)

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/screenshot.png)

## What's in it?

These are the main configs:

- [Homebrew](https://brew.sh/) to manage installing most of the dependencies, including apps using [Cask](https://github.com/caskroom/homebrew-cask)
- [Mutt](http://www.mutt.org/) for reading emails
- [tmux](http://tmux.sourceforge.net/) 2.3 or later
- [Neovim](https://neovim.io) or [Vim](http://www.vim.org/) 8.0 or later with Ruby and Python support
- [Zsh](http://www.zsh.org/)
- [Git](http://git-scm.com/)
- [iTerm2](http://www.iterm2.com/)
- [newsbeuter](http://newsbeuter.org/) for RSS
- [weechat](https://weechat.org/) IRC client
- [hammerspoon](http://www.hammerspoon.org/)
- [Python](https://www.python.org/)
- [Ruby](https://www.ruby-lang.org/)

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

### Authors

[Ahmed El Gabri](https://twitter.com/AhmedElGabri)
