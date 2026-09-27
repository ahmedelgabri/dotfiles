# Scripts

Shell scripts packaged by `nix/parts/outputs/apps.nix` with `writeShellApplication`, which runs shellcheck on them at build time. None of them is executed directly.

| Script | Flake app | Purpose |
| --- | --- | --- |
| `aarch64-darwin_bootstrap`, `x86_64-linux_bootstrap` | `default` | First install of a host (see the root README) |
| `utils` | — | Logging helpers and `clone_dotfiles`, sourced by both bootstrap scripts |
| `doctor` | `doctor` | Checklist of the setup bootstrap cannot do |

## doctor

`nix run ~/.dotfiles#doctor` prints `[ok]` or `[!!]` for each item and exits non-zero while anything is missing. Both bootstrap scripts put the same derivation on their `PATH` and run it last, without failing on it, so the result doubles as the post-install to-do list.

| Check | Passes when |
| --- | --- |
| dotfiles checkout | `~/.dotfiles/flake.nix` exists |
| system generation | `/run/current-system` exists |
| login shell | the account's shell is zsh, read from `dscl` (macOS) or `getent` (Linux) because `$SHELL` can be stale |
| SSH key pair | a `~/.ssh/*.pub` key has its private key next to it |
| GPG secret key | the keyring in `$GNUPGHOME` (default `~/.config/gnupg`) holds a secret key; git signs commits |
| pass store | `.gpg-id` exists in `$PASSWORD_STORE_DIR` or `~/.password-store` |
| agenix | `~/.npmrc` links into `/run/agenix` and is readable |

The probes are read-only: they never print secrets, create files or start agents. GPG is queried with `--batch --no-autostart` and only when a keyring already exists, because listing keys in an empty home creates `pubring.kbx` and `trustdb.gpg`. On macOS agenix decrypts from a launchd daemon, so the agenix check can fail for a moment right after activation.
