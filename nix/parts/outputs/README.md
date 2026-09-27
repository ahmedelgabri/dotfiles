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
| `<host>-eval` | Every darwin host of the current system evaluates |

### Darwin host evaluation

`nix flake check` does not evaluate `darwinConfigurations`, so each darwin host gets a `<host>-eval` check generated from them. It writes the host's system `drvPath` with its string context discarded, which forces a full evaluation without building the host's closure; running it locally takes seconds.

On the Ubuntu runner, `--all-systems` evaluates these aarch64-darwin checks without building them. That only works while no evaluation step needs a darwin build, so the workflow passes `--option allow-import-from-derivation false` to fail fast if import-from-derivation creeps in. A host that imports a private flake input needs CI access to it, or has to be left out.
