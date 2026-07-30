# Neovim

A fully Lua Neovim configuration that runs in two modes from the same files: live-editable on managed hosts, and as a sealed standalone Nix package.

## Normal mode (managed hosts)

Home Manager symlinks this directory to `~/.config/nvim` out of the store ([vim.nix](../../nix/parts/modules/shared/vim.nix)), so edits apply without a rebuild. Plugins are managed at runtime by Neovim's native `vim.pack`, wrapped by [lua/\_/pack.lua](./lua/_/pack.lua) which adds lazy-loading triggers (`event`/`ft`/`cmd`) on top. `vim.pack` pins plugins in [nvim-pack-lock.json](./nvim-pack-lock.json); the lock is committed because it also drives the standalone package below, so run `vim.pack.update()` and commit the resulting diff to update plugins. LSP servers, formatters and linters come from [vim-tools.nix](../../nix/parts/modules/shared/vim-tools.nix) as regular user packages.

## Standalone mode (`nix run`)

The flake exposes a fully self-contained Neovim built with the neovim module from [nix-wrapper-modules](https://github.com/BirdeeHub/nix-wrapper-modules):

```bash
nix run ~/.dotfiles#neovim
# or from anywhere
nix run 'github:ahmedelgabri/dotfiles#neovim'
```

How it fits together (see [neovim.nix](../../nix/parts/outputs/neovim.nix)):

- This config directory is baked into the store and prepended to `runtimepath`/`packpath`, so `init.lua`, `plugin/`, `lua/` and `colors/` behave exactly as in normal mode. The user's `~/.config/nvim` is blocked.
- The plugin set comes from [nvim-pack-lock.json](./nvim-pack-lock.json): each entry is fetched shallowly at its locked rev with `builtins.fetchGit`, which pure eval allows, so both modes run the exact same plugin revisions. Each plugin lands in `pack/…/opt/<name>` where `<name>` is the lock entry name — the same name `pack.lua` derives for `:packadd`.
- `pack.lua` detects the wrapper via `vim.g.nix_info_plugin_name` and skips `vim.pack` entirely; the same `:packadd`-based lazy loading drives both modes.
- The tool list from `vim-tools.nix` (plus `git`, `curl`, and `gcc` on Linux for tree-sitter's runtime parser compilation) is put on the wrapped Neovim's `$PATH`, so nothing needs to be installed system-wide.

Note that plugins are fetched at evaluation time, so the first build on a new machine needs network access during eval; afterwards everything is cached.

### Conventions the Nix side relies on

- Adding a plugin means adding its spec in `plugin/*.lua` and letting `vim.pack` update the lock; the Nix package follows the lock automatically.
- If a spec pins a `version = '<branch>'` that differs from the repo's default branch, add it to `branchRefs` in [neovim.nix](../../nix/parts/outputs/neovim.nix) so the locked rev is reachable; tree-sitter's `main` repos are the current cases.
- Plugins whose `build` hooks produce compiled artifacts can't run under Nix; they are substituted with nixpkgs builds via `prebuilt` in `neovim.nix` (currently `blink.cmp` and `LuaSnip`), so their revs may differ from the lock.
