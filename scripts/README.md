# Scripts

Shell scripts packaged by `nix/parts/outputs/apps.nix` with
`writeShellApplication`, which runs shellcheck on them at build time. None of
them is executed directly.

| Script                                               | Flake app                | Purpose                                                                                                                                                                                                                                            |
| ---------------------------------------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `aarch64-darwin_bootstrap`, `x86_64-linux_bootstrap` | `default`                | First install of a host (see the root README)                                                                                                                                                                                                      |
| `utils`                                              | —                        | Argument parsing, logging helpers, `clone_dotfiles`, and `host_cache_options`, sourced by both bootstrap scripts. The last passes the host's binary caches to the first switch, since they only reach `nix.conf` once that switch has applied them |
| `doctor`                                             | `doctor`                 | Checklist of the setup bootstrap cannot do                                                                                                                                                                                                         |
| `test-bootstrap`                                     | `test-bootstrap` (macOS) | Runs bootstrap in a disposable Tart VM                                                                                                                                                                                                             |

## doctor

`nix run ~/.dotfiles#doctor` prints `[ok]` or `[!!]` for each item and exits
non-zero while anything is missing. Both bootstrap scripts put the same
derivation on their `PATH` and run it last, without failing on it, so the result
doubles as the post-install to-do list.

| Check             | Passes when                                                                                            |
| ----------------- | ------------------------------------------------------------------------------------------------------ |
| dotfiles checkout | `~/.dotfiles/flake.nix` exists                                                                         |
| system generation | `/run/current-system` exists                                                                           |
| login shell       | the account's shell is zsh, read from `dscl` (macOS) or `getent` (Linux) because `$SHELL` can be stale |
| SSH key pair      | a `~/.ssh/*.pub` key has its private key next to it                                                    |
| GPG secret key    | the keyring in `$GNUPGHOME` (default `~/.config/gnupg`) holds a secret key; git signs commits          |
| pass store        | `.gpg-id` exists in `$PASSWORD_STORE_DIR` or `~/.password-store`                                       |
| agenix            | `~/.npmrc` links into `/run/agenix` and is readable                                                    |

The probes are read-only: they never print secrets, create files or start
agents. GPG is queried with `--batch --no-autostart` and only when a keyring
already exists, because listing keys in an empty home creates `pubring.kbx` and
`trustdb.gpg`. On macOS agenix decrypts from a launchd daemon, so the agenix
check can fail for a moment right after activation.

## test-bootstrap

Bootstrap only runs on fresh machines, so it can break unnoticed.
`nix run .#test-bootstrap -- --host <host>` runs it in a throwaway
[Tart](https://tart.run) VM cloned from `ghcr.io/cirruslabs/macos-tahoe-vanilla`
(override with `--image`; `--keep` leaves the VM running for inspection). It
needs `tart` from Homebrew; no Pragmata Pro archive is required. It is a full
workstation install over the network, including every Homebrew cask, so it takes
a long time.

The guest runs
`nix run github:ahmedelgabri/dotfiles -- <host> --without-pragmatapro` with no
`~/.dotfiles` directory. This tests the published repository, not unpushed local
changes. The font flag and matching host variants must be published before
running the test. The test passes only when bootstrap exits 0 and creates a Git
checkout containing `flake.nix`. `doctor` reports SSH, GPG, pass and agenix as
missing, which is expected: production keys are never copied into the VM, and
its host key is not an agenix recipient. Logs go to
`~/.local/state/dotfiles-test-bootstrap/<vm>/`.

Getting a stock macOS image to the point where bootstrap can run needs a few
workarounds:

| Problem                                                                                      | Handling                                                                                                                                                                                                               |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `xcode-select --install` needs a GUI click                                                   | Install the Command Line Tools with `softwareupdate` behind the on-demand marker file                                                                                                                                  |
| nix-darwin needs the user's GUI launchd session                                              | Create the host's user with passwordless sudo, enable auto-login and reboot. `sysadminctl -autologin set` fails with `SACSetAutoLoginPassword error:22` while exiting 0, so the script writes `/etc/kcpassword` itself |
| A reboot can finish between polls                                                            | Compare `kern.boottime` before and after instead of waiting for the guest to go down                                                                                                                                   |
| The boot container cannot grow: a recovery container follows it and SIP refuses to delete it | Add a separate APFS container in the extra disk space and install Nix onto it with `--root-disk`                                                                                                                       |
| Disk identifiers are renumbered on reboot                                                    | Create that container after the reboot, right before installing Nix                                                                                                                                                    |
| `requireFile` needs Pragmata Pro                                                             | Pass `--without-pragmatapro` for this run; the default configuration still requires the font                                                                                                                           |
| Bootstrap must create the checkout                                                           | Leave `~/.dotfiles` absent, run the published bootstrap, then verify its clone                                                                                                                                         |
| No TTY or `TERM`                                                                             | `utils` falls back to plain output when `tput` fails, instead of aborting under `set -e`                                                                                                                               |

SSH to the guest uses only command-line options (`-F /dev/null`, a per-run
known_hosts file, no agent forwarding or public keys), so nothing from the
host's SSH setup reaches the VM. Every wait has a timeout, cleanup is trapped
before the VM exists, and the VM is deleted on any exit unless `--keep` is
passed.
