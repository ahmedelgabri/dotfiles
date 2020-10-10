# ~ 🍭 ~

For setting up development environment on new Mac. The config is managed by
[Ansible](https://www.ansible.com/)

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/screenshot.png)

## What's in it?

These are the main configs:

- [Homebrew][homebrew] to manage installing most of the dependencies, including
  apps using [Cask](https://github.com/caskroom/homebrew-cask)
- [neomutt][neomutt] for reading emails
- [tmux][tmux] 2.3 or later
- [Neovim][neovim] or [Vim][vim] 8.0 or later with Ruby and Python support
- [Zsh][zsh]
- [Git][git]
- [Kitty][kitty] as my terminal
- [newsboat][newsboat] for RSS
- [weechat][weechat] IRC client
- [hammerspoon][hammerspoon] macOS automation, using it for window management &
  other stuff
- [node][node]
- [Python][python]

## Installation

1. Name your computer in System Preferences -> Sharing

2. Install Xcode & Command line tools, do it manually. Automation doesn't work
   nice here.

```bash
$ xcode-select --install
```

3. Run the following command

```bash
$ bash -c "$(curl -fsSL https://raw.github.com/ahmedelgabri/dotfiles/master/install)"
```

### Notes

- zsh: add these to `~/.zshrc.local`

```zsh
export HOMEBREW_GITHUB_API_TOKEN =
export GITHUB_TOKEN =
export WEECHAT_PASSPHRASE =
```

- For git add your GPG key info in `~/.gitconfig.local`

```
[user]
  signingkey =
```

Don't forget to upload your public key to GitHub!
https://github.com/blog/2144-gpg-signature-verification Note: There needs to be
a three-way match on your email for GitHub to show the commit as 'verified': The
commit email, github email, & the email associated with the public key

Learn about creating a GPG key and the knowledge behind these commands here:
https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work

#### Email

I have two email accounts (personal/work) The messages are synchronised between
the remote server and my computer with [isync][isync], I read them with
[neomutt][neomutt] and search index is built by [notmuch][notmuch].

After linking the dotfiles, there are only a few more things that need to be
done.

##### Authentication

Each account must authenticate with an IMAP server and an SMTP server. The
passwords, need be stored in the [OS X keychain][keychain].

For Gmail accounts with two-factor authentication enabled, use an
application-specific password.

In order for all this to work, a few items have to be stored in the macOS
keychain:

Create a "generic"(A.K.A. "application") keychain item (that is, without
protocols, only hostnames):

For sending mail:

- An item with (for Gmail):
  - "Keychain Item Name": gmail.com
  - "Account Name": username+mutt@gmail.com - An item with (for Gmail)

**Repeat this for each account you want to add.**

## Synchronizing periodically

Incoming messages are fetched from the remote server when `mbsync` runs (the
executable name for isync).

To run `mbsync` periodically, load the [`launchctl`][launchctl] job with:

```shell
$ launchctl load ~/Library/LaunchAgents/com.ahmedelgabri.isync.plist
```

This will run `mbsync -a` every 2 minutes, synchronizing all IMAP folders.

### Authors

[Ahmed El Gabri](https://twitter.com/AhmedElGabri)

[isync]: http://isync.sourceforge.net
[notmuch]: https://notmuchmail.org
[keychain]: https://en.wikipedia.org/wiki/Keychain_(software)
[launchctl]: http://launchd.info
[neomutt]: https://neomutt.org/
[homebrew]: https://brew.sh/
[tmux]: http://tmux.sourceforge.net/
[neovim]: https://neovim.io
[zsh]: http://www.zsh.org/
[git]: http://git-scm.com/
[kitty]: https://github.com/kovidgoyal/kitty
[newsboat]: http://newsboat.org/
[weechat]: https://weechat.org/
[hammerspoon]: http://www.hammerspoon.org/
[node]: https://nodejs.org
[python]: https://www.python.org/
