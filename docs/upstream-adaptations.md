# Upstream dotfiles adaptations

## Finder file opens

Finder's "Open with Kitty" and `kitty +open <file>` reuse a running Neovim through `kitty-launch-open`. Directories and images keep their overlay actions. Other files are classified by content rather than extension. Text and empty files go to our existing opener; binary files go to the default macOS application. If no editor is reachable, the Finder handler creates an OS window running `$EDITOR`, defaulting to Neovim. The clicked-link handler still never creates an editor.

The opener remains local to this repository. Compared with Shannon's opener, it supports standalone Kitty windows, ranks nearby editors, preserves column positions, recognizes more URL forms, supports explicit Neovim listen addresses, and safely quotes unusual filenames. Shannon adds SSH forwarding and binary handling, but its remote plugin path assumes Wincent's deployment. The Finder wrapper adds binary handling without losing our local behavior.

Kitty grants background launch actions remote control through an inherited socket descriptor. The Python opener explicitly preserves that descriptor only when spawning Kitty commands. The wrapper adds Nix's per-user binaries to its PATH so macOS LaunchServices does not accidentally select the system Python.

A Home Manager switch is needed to install the wrapper symlink.

## Spell dictionaries

Home Manager installs pinned English and Dutch UTF-8 dictionaries and suggestion files in `$XDG_DATA_HOME/nvim/site/spell`. NLUUG and FU Berlin serve byte-identical files for all four downloads; `fetchurl.urls` provides mirror fallback and the fixed hashes prevent accepting changed content. ICM returned HTTP 502 during verification and is not included.

These files are separate from `config/nvim/spell/spell.add` and its compiled `spell.add.spl`. Your accepted words remain writable and are not replaced. The configuration does not force replacement of existing differing files; Home Manager will report a collision instead. Run your normal Home Manager or system switch to install the files.

## Presentation exports

Use `:Keynote` to export the whole buffer or `:'<,'>Keynote` to export a visual selection. Numeric line ranges also work, such as `:10,20Keynote`. The command generates syntax-colored HTML using Neovim's bundled `nvim.tohtml`, requests `PragmataPro Mono Liga`, omits line numbers, and opens the file through `vim.ui.open`, which uses plain `open` on macOS. It does not require Chrome or control Keynote itself. Copy the rendered code from the default browser into your presentation.

The source buffer, its contents, and its line-number setting remain unchanged. The exported file lives in Neovim's temporary directory and is removed when Neovim exits. Failed writes or browser launches report an error rather than pretending the export succeeded.

## Sandbox image builds

`sb build-image` builds under a staging name, verifies package health, English locales, SSH configuration, and the installed Git, Jujutsu, Node, Claude, and Pi executables before publishing the base. Locale generation runs after package installation and persists the choices in debconf. SSH keepalives bound unresponsive connections, and error traps report the failing command, line, and status.

`sb build-image --force` keeps the existing base until the replacement has passed verification and shut down. Publication renames the previous base aside, renames the staged image into place, and deletes the previous image only after success. A failed promotion restores the previous base name. Running bases cannot be replaced.

Failed or interrupted builds stop and retain the staging VM instead of deleting the evidence. The failure output includes commands to start, connect to, and discard that VM. Inspect it with `tart run --no-graphics <name>` and `ssh admin@$(tart ip <name>)`, using the disposable guest password `admin`. Delete it when finished with `tart delete <name>`.

The implementation keeps our project-oriented commands, registry behavior, and graceful successful shutdown. It adapts the verification and failure-handling ideas from [Wincent's VM manager](https://github.com/wincent/wincent/blob/df97b31ef8699f243e219b3aaf51b81f5f056c55/bin/vm) rather than replacing `sb`.

## Validation history

The implementation was validated with unit, integration, and end-to-end tests on macOS. The seven added test files and four feature-specific flake checks were removed at the owner's request to keep this dotfiles repository small. Existing tests and checks were left intact. Nix formatting, StyLua, ShellCheck, typos, and all-system flake evaluation passed during implementation.

Real Kitty launch actions passed with and without tmux under a minimal macOS-style PATH. The HTML test opened a sample in the actual default browser. The real Tart run passed initial creation, refusal without `--force`, preservation after a failed forced build, successful replacement, and fresh-boot verification of all five tools. Installer diagnostics were captured and checked against explicit expected notices. All test VMs and downloaded OCI images were removed, leaving an empty Tart inventory and cache. No system or Home Manager switch was performed.
