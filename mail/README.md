# Email

The files in this folder define the configuration of the programs I use to
fetch, read, and search my emails.

I have two email accounts, one for work and one for personal emails. The
messages are syncronised between the remote server and my computer with
[isync][isync], and I read them with [NeoMutt][neomutt]. A search index is
built by [notmuch][notmuch], and emails are sent with [msmtp][msmtp].

After linking the dotfiles with `stow mail` in the
`~/.dotfiles` directory, there are only a few more things that need to be done.

## Authentication

Each account must authenticate with an IMAP server and an SMTP server. The
passwords, need be stored in the [OS X keychain][keychain]. The
IMAP items should be named as in the `PassCmd` directive in the
[`.mbsyncrc`](.mbsyncrc) file. The SMTP items should be named as
`smtp://smtp.theserver.tld`. In both cases the account should be the login
account of the server.

For Gmail accounts with two-factor authentication enabled, use an
application-specific password.

In order for all this to work, a few items have to be stored in the macOS keychain:

Create a "generic"(A.K.A. "application") keychain item (that is, without protocols, only hostnames):

For sending mail:
- An item with (for Gmail):
    - "Keychain Item Name": smtp.gmail.com (corresponds to the "host" field in ~/.msmtprc).
    - "Account Name": username+mutt@example.com (corresponds to the "user" field in ~/.msmtprc).
- An item with (for Gmail):
    - "Keychain Item Name": imap.gmail.com (corresponds to the "Host" field in ~/.mbsyncrc).
    - "Account Name": username+mutt@example.com (corresponds to the "PassCmd" field in ~/.mbsyncrc).

**Repeat this for each account you want to add.**

## Synchronising periodically

Emails are sent by the `msmtp` program when they're sent in NeoMutt. Incoming
messages are fetched from the remote server when `mbsync` runs (the executable
name for isync).

To run `mbsync` periodically, load the [`launchctl`][launchctl] job with:

```shell
$ launchctl load ~/Library/LaunchAgents/com.ahmedelgabri.isync.plist
```

This will run `mbsync -a` every 2 minutes, synchronising all IMAP folders.

[isync]: http://isync.sourceforge.net
[neomutt]: http://www.neomutt.org/
[notmuch]: https://notmuchmail.org
[msmtp]: http://msmtp.sourceforge.net
[keychain]: https://en.wikipedia.org/wiki/Keychain_(software)
[launchctl]: http://launchd.info
