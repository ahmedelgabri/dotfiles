# Flake outputs

Each file here contributes one kind of flake output through flake-parts.

## Checks

`checks.nix` backs `nix flake check`, which CI runs as `nix flake check --all-systems` on Ubuntu (`.github/workflows/nix-eval.yml`).

| Check | What it enforces |
| --- | --- |
| `deadnix` | No unused Nix bindings or arguments. `nix/parts/hosts/nixos/hardware-configuration.nix` is excluded: `nixos-generate-config` owns it and would bring its unused argument back on every regeneration. |
| `nix-format` | `nixfmt-rs` formatting |
| `pi-extensions` | The pi extensions type-check with `tsc` |
| `shellcheck` | Every bash or `sh` script in the repo |
| `stylua` | Lua formatting under `config/` |
| `typos` | Spelling |
| `next-prayer` | The Go package builds and its tests pass |
