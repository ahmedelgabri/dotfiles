# ~ 🍭 ~

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

For setting up development environment on any Unix machine (Darwin/Linux). The
config officially supports macOS & NixOS & managed by [nix][nix]

![screenshot](./screenshot.png)

> _Font is [Pragmata Pro](https://fsd.it/shop/fonts/pragmatapro/), theme is a
> [my own](./config/nvim/colors/plain.lua) fork of
> [vim-colors-plain](https://github.com/andreypopp/vim-colors-plain), Terminal
> is [Ghostty][Ghostty]_

## What's in it?

These are the main configs:

- [nix][nix] to manage installing most of the dependencies, for GUI apps on
  macsOS I'm still using
  [Homebrew cask](https://github.com/caskroom/homebrew-cask) through the
  homebrew module in
  [`nix-darwin`](https://github.com/LnL7/nix-darwin/blob/5c3146b75d5d478f0693d0ea6c83f1da8382ff56/modules/homebrew.nix)
- [aerc][aerc] for reading emails
- [tmux][tmux] 2.3 or later
- [Neovim][neovim]
- [Zsh][zsh]
- [Git][git]
- [Ghostty][Ghostty] as my terminal
- [hammerspoon][hammerspoon] macOS automation, using it for window management &
  other stuff

## Officially supported OSs

- ARM macOS Sequoia
- [Experimental] NixOS (tested on 22.11)

## Installation

1. Install `nix`

> [!NOTE]
>
> Make sure to check the
> [`quirks`](https://github.com/NixOS/experimental-nix-installer/blob/main/docs/quirks.md)
> section

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://artifacts.nixos.org/experimental-installer | sh -s -- install
```

1. Set up

> [!NOTE]
>
> The flake attribute in my case is usually is the host machine name, if not
> passed it will default to `$(hostname -s)`

online:

```bash
nix run "github:ahmedelgabri/dotfiles" -- <flake attribute>
```

### Homebrew

I still use it mostly for GUI apps, since Nix and/or Home-manager support for
GUI applications have problems with symlinking to the `Applications/` folder.
Homebrew is fully managed by `nix` it gets installed and run through nix using
[`nix-homebrew`](https://github.com/zhaofengli/nix-homebrew)

### Notes

- zsh: add these to `${XDG_DATA_HOME}/$(hostname)/zshrc`

```zsh
export HOMEBREW_GITHUB_API_TOKEN =
export GITHUB_TOKEN =
```

- For git add your GPG key info in `${XDG_DATA_HOME}/$(hostname)/gitconfig`

```
[user]
  signingkey =
```

Don't forget to upload your public key to
[GitHub](https://github.com/blog/2144-gpg-signature-verification)!

> Note: There needs to be a three-way match on your email for GitHub to show the
> commit as 'verified': The commit email, github email, & the email associated
> with the public key

Learn about creating a GPG key and signing your commits
[here](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work)

#### Email

My email messages are synchronised between the remote server and my computer
with [isync][isync], I read them with [aerc][aerc] and search index is built by
[notmuch][notmuch].

After linking the dotfiles, there are only a few more things that need to be
done.

##### Authentication

Each account must authenticate with an IMAP server and an SMTP server. The
passwords, need be stored in the [Pass][Pass].

For Fastmail (or Gmail accounts with two-factor authentication enabled), use an
application-specific password.

In order for all this to work, a few items have to be stored in the password
store:

- `service/email/source`: (_used by fastmail only_ JMAP password to access my
  email)
- `service/email/outgoing`: (_used by fastmail only_ JMAP password to send
  emails)
- `service/email/contacts`: (_used by fastmail only_ JMAP password to access
  contacts)
- `service/email/password`: App specific password, needed for local email
  syncing `mbsync` and sending emails with `msmtp`

## Synchronizing periodically

Incoming messages are fetched from the remote server when `mbsync` runs (the
executable name for isync).

On macs I use [`launchd`][launchd], on NixOS using `systemd`. You can check
[`mail.nix`](nix/modules/mail.nix).

### Authors

[Ahmed El Gabri](https://twitter.com/AhmedElGabri)

[isync]: http://isync.sourceforge.net
[notmuch]: https://notmuchmail.org
[keychain]: https://en.wikipedia.org/wiki/Keychain_(software)
[launchd]: http://launchd.info
[aerc]: https://aerc-mail.org/
[nix]: https://nixos.org/
[tmux]: http://tmux.sourceforge.net/
[neovim]: https://neovim.io
[zsh]: http://www.zsh.org/
[git]: http://git-scm.com/
[kitty]: https://github.com/kovidgoyal/kitty
[hammerspoon]: http://www.hammerspoon.org/
[Ghostty]: https://ghostty.org/
[Pass]: https://www.passwordstore.org/

## Architecture

This configuration uses [flake-parts](https://flake.parts/) with the [Dendritic Pattern](https://github.com/mightyiam/dendritic):

- **Auto-discovery**: All modules under `nix/` are auto-discovered via [import-tree](https://github.com/vic/import-tree)
- **Aspect-oriented**: Organized by feature (git, vim), not platform (darwin, nixos)
- **Feature modules**: Each feature in `nix/modules/` works across all systems
- **System modules**: Core configuration in `nix/system/`
- **Host configs**: Single file per host in `nix/hosts/`

See [DENDRITIC-MIGRATION.md](./DENDRITIC-MIGRATION.md) for complete architecture details.
