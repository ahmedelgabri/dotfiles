# My [.]files

For setting up development environment on new Mac. The config is managed by
[GNU stow](https://www.gnu.org/software/stow/)

![screenshot](https://raw.githubusercontent.com/ahmedelgabri/dotfiles/master/screenshot.png)

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
- [Kitty](https://github.com/kovidgoyal/kitty)
- [newsboat](http://newsboat.org/) for RSS
- [weechat](https://weechat.org/) IRC client
- [hammerspoon](http://www.hammerspoon.org/)
- [Python](https://www.python.org/)
- [Ruby](https://www.ruby-lang.org/)

## Installation

1. Install Xcode & Command line tools, do it manually. Automation doesn't work
   nice here.

2. Run one of these commands

```bash
$ bash <(curl -fsSL https://raw.github.com/ahmedelgabri/dotfiles/master/script/install)
```

or

```sh
$ git clone https://github.com/ahmedelgabri/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make install
```

### Notes

- For ZSH you have to update `~/.zshrc.local` which should be copied
  automatically, if not, you can run the following command.

```sh
$ cp files/.zshrc.local.example ~/.zshrc.local
```

- For git you have to update `~/.gitconfig.local` which should be copied
  automatically, if not, you can run the following command.

```sh
$ cp files/.gitconfig.local.example ~/.gitconfig.local
```

Don't forget to upload your public key to GitHub!
https://github.com/blog/2144-gpg-signature-verification Note: There needs to be
a three-way match on your email for GitHub to show the commit as 'verified': The
commit email, github email, & the email associated with the public key

Learn about creating a GPG key and the knowledge behind these commands here:
https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work

#### Email

I have two email accounts, one for work and one for personal emails. The
messages are syncronised between the remote server and my computer with
[isync][isync], and I read them with [NeoMutt][neomutt]. A search index is built
by [notmuch][notmuch], and emails are sent with [msmtp][msmtp].

After linking the dotfiles, there are only a few more things that need to be
done.

##### Authentication

Each account must authenticate with an IMAP server and an SMTP server. The
passwords, need be stored in the [OS X keychain][keychain]. The IMAP items
should be named as in the `PassCmd` directive in the [`.mbsyncrc`](.mbsyncrc)
file. The SMTP items should be named as `smtp://smtp.theserver.tld`. In both
cases the account should be the login account of the server.

For Gmail accounts with two-factor authentication enabled, use an
application-specific password.

In order for all this to work, a few items have to be stored in the macOS
keychain:

Create a "generic"(A.K.A. "application") keychain item (that is, without
protocols, only hostnames):

For sending mail:

- An item with (for Gmail):
  - "Keychain Item Name": smtp.gmail.com (corresponds to the "host" field in
    ~/.msmtprc).
  - "Account Name": username+mutt@example.com (corresponds to the "user" field
    in ~/.msmtprc).
- An item with (for Gmail):
  - "Keychain Item Name": imap.gmail.com (corresponds to the "Host" field in
    ~/.mbsyncrc).
  - "Account Name": username+mutt@example.com (corresponds to the "PassCmd"
    field in ~/.mbsyncrc).

**Repeat this for each account you want to add.**

## Synchronizing periodically

Emails are sent by the `msmtp` program when they're sent in NeoMutt. Incoming
messages are fetched from the remote server when `mbsync` runs (the executable
name for isync).

To run `mbsync` periodically, load the [`launchctl`][launchctl] job with:

```shell
$ launchctl load ~/Library/LaunchAgents/com.ahmedelgabri.isync.plist
```

This will run `mbsync -a` every 2 minutes, synchronizing all IMAP folders.

[isync]: http://isync.sourceforge.net
[neomutt]: http://www.neomutt.org/
[notmuch]: https://notmuchmail.org
[msmtp]: http://msmtp.sourceforge.net
[keychain]: https://en.wikipedia.org/wiki/Keychain_(software)
[launchctl]: http://launchd.info

### Authors

[Ahmed El Gabri](https://twitter.com/AhmedElGabri)
