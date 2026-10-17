# mx configuration

Linked to `~/.config/mx/` by the `tmux` feature. [`nix/pkgs/mx/README.md`](../../nix/pkgs/mx/README.md) documents the formats.

- [`shared.lua`](shared.lua): windows that every new session gets after its own.
- `sessions/<name>.lua`: definitions shared by every host. Machine-specific ones go in `$HOST_CONFIGS/mx/sessions/` instead, which wins when both have the same name.
