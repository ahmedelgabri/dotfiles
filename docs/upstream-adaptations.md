# Upstream dotfiles adaptations

## Finder file opens

Finder's "Open with Kitty" and `kitty +open <file>` reuse a running Neovim through `kitty-launch-open`. Directories and images keep their overlay actions. Other files are classified by content rather than extension. Text and empty files go to our existing opener; binary files go to the default macOS application. If no editor is reachable, the Finder handler creates an OS window running `$EDITOR`, defaulting to Neovim. The clicked-link handler still never creates an editor.

The opener remains local to this repository. Compared with Shannon's opener, it supports standalone Kitty windows, ranks nearby editors, preserves column positions, recognizes more URL forms, supports explicit Neovim listen addresses, and safely quotes unusual filenames. Shannon adds SSH forwarding and binary handling, but its remote plugin path assumes Wincent's deployment. The Finder wrapper adds binary handling without losing our local behavior.

Kitty grants background launch actions remote control through an inherited socket descriptor. The Python opener explicitly preserves that descriptor only when spawning Kitty commands. The wrapper adds Nix's per-user binaries to its PATH so macOS LaunchServices does not accidentally select the system Python.

A Home Manager switch is needed to install the wrapper symlink.

## Sandbox image builds

`sb build-image` builds under a staging name, verifies package health, English locales, SSH configuration, and the installed Git, Jujutsu, Node, Claude, and Pi executables before publishing the base. Locale generation runs after package installation and persists the choices in debconf. SSH keepalives bound unresponsive connections, and error traps report the failing command, line, and status.

`sb build-image --force` keeps the existing base until the replacement has passed verification and shut down. Publication renames the previous base aside, renames the staged image into place, and deletes the previous image only after success. A failed promotion restores the previous base name. Running bases cannot be replaced.

Failed or interrupted builds stop and retain the staging VM instead of deleting the evidence. The failure output includes commands to start, connect to, and discard that VM. Inspect it with `tart run --no-graphics <name>` and `ssh admin@$(tart ip <name>)`, using the disposable guest password `admin`. Delete it when finished with `tart delete <name>`.

The implementation keeps our project-oriented commands, registry behavior, and graceful successful shutdown. It adapts the verification and failure-handling ideas from [Wincent's VM manager](https://github.com/wincent/wincent/blob/df97b31ef8699f243e219b3aaf51b81f5f056c55/bin/vm) rather than replacing `sb`.
