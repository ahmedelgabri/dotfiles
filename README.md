# My [.]files

For setting up development environment on new Mac. The config is managed by
[GNU stow](https://www.gnu.org/software/stow/)

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/latest.png)

## What's in it?

These are the main configs:

- [Homebrew](https://brew.sh/) to manage installing most of the dependencies,
  including apps using [Cask](https://github.com/caskroom/homebrew-cask)
- [NeoMutt](https://www.neomutt.org/) _improved [Mutt](http://www.mutt.org/)_
  for reading emails
- [tmux](http://tmux.sourceforge.net/) 2.3 or later
- [Neovim](https://neovim.io) or [Vim](http://www.vim.org/) 8.0 or later with
  Ruby and Python support
- [Zsh](http://www.zsh.org/)
- [Git](http://git-scm.com/)
- [iTerm2](http://www.iterm2.com/)
- [newsboat](http://newsboat.org/) for RSS
- [weechat](https://weechat.org/) IRC client
- [hammerspoon](http://www.hammerspoon.org/)
- [Python](https://www.python.org/)
- [Ruby](https://www.ruby-lang.org/)

## Installation

```bash
$ bash -c "$(curl -fsSL https://raw.github.com/ahmedelgabri/dotfiles/master/script/install)"
```

or

```sh
$ git clone https://github.com/ahmedelgabri/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make install
```

### Notes

#### ZSH setup

These env variables are needed inside `~/.zshrc.local`

```zsh
export NAME
export GITHUB_USER
export HOMEBREW_GITHUB_API_TOKEN
export GITHUB_TOKEN
export JIRA_API_TOKEN # Optional

export WORK=<PATH TO WORK FOLDER>
# anything else that shouldn't be publicly shared
```

#### A quick outline of what must be done to get gpg & git working.

Configure git to automatically gpgsign commits. This consists of pointing git to
your signing key ID, and then enabling commit automatic signing.

This info should be in `gitconfig.local`

```sh
git config --global user.name <YOUR-NAME>
git config --global user.email <YOUR-EMAIL>
git config --global user.signingkey <YOUR-SIGNING-KEY-PUB-ID>
```

Don't forget to upload your public key to Github!
https://github.com/blog/2144-gpg-signature-verification Note: There needs to be
a three-way match on your email for Github to show the commit as 'verified': The
commit email, github email, & the email associated with the public key

Learn about creating a GPG key and the knowledge behind these commands here:
https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work

### Authors

[Ahmed El Gabri](https://twitter.com/AhmedElGabri)
