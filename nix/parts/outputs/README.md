# Flake outputs

Each file here contributes one kind of flake output through flake-parts.

## Checks

`checks.nix` backs `nix flake check`. `nix run .#lint` (in `apps.nix`) runs it with `--all-systems` and then zizmor's online audits (see below); CI runs the same app on Ubuntu (`.github/workflows/nix-eval.yml`).

| Check | What it enforces |
| --- | --- |
| `deadnix` | No unused Nix bindings or arguments. `nix/parts/hosts/nixos/hardware-configuration.nix` is excluded: `nixos-generate-config` owns it and would bring its unused argument back on every regeneration. |
| `actionlint` | GitHub workflows are valid (syntax, expressions, runner labels), with shellcheck over their `run:` scripts |
| `zizmor` | GitHub workflows and `dependabot.yml` pass zizmor's offline security audits. Checks have no network or token, so the online audits run separately (see below) |
| `nix-format` | `nixfmt-rs` formatting |
| `pi-extensions` | The pi extensions and their colocated TypeScript tests type-check with `tsc` |
| `pi-diff` | Node unit and integration tests for diff parsing, annotation persistence, preferences, real repositories, and conflict-file safety; [E2E instructions](../../../config/pi/agent/extensions/diff/README.md#tests) |
| `shellcheck` | Every bash or `sh` script in the repo |
| `stylua` | Lua formatting under `config/` |
| `typos` | Spelling |
| `next-prayer` | The Go package builds and its offline unit and integration tests pass; [live API tests](../../pkgs/next-prayer/README.md#live-end-to-end-tests) run separately |
| `hammerspoon-prayer` | Prayer selection, date rollover, notification scheduling, retries, and location changes with a controlled Lua runtime |
| `doctor-tests` | Setup detection, platform-specific probes, exit status, and read-only behavior |
| `get-prayer` | Prayer wrapper source selection, location parsing, fallback, JSON output, and failure status; see [tests](../../../tests/README.md) |
| `bootstrap-args` | Bootstrap parses the host and run-only font flag, preserves the default, and rejects invalid arguments |
| `bootstrap-fonts` | Normal hosts enable Pragmata Pro; font-free variants remove only that font and retain the host identity |
| `<host>-eval` | Every darwin host of the current system evaluates, including its `-without-pragmatapro` variant |

### Darwin host evaluation

`nix flake check` does not evaluate `darwinConfigurations`, so each darwin host gets a `<host>-eval` check generated from them. It writes the host's system `drvPath` with its string context discarded, which forces a full evaluation without building the host's closure; running it locally takes seconds.

On the Ubuntu runner, `--all-systems` evaluates these aarch64-darwin checks without building them. That only works while no evaluation step needs a darwin build, so the workflow passes `--option allow-import-from-derivation false` to fail fast if import-from-derivation creeps in. A host that imports a private flake input needs CI access to it, or has to be left out.

### Keeping CI current

Workflows pin actions by commit SHA. `.github/dependabot.yml` bumps those pins (and their version comments) weekly in a single grouped PR with a `ci` commit prefix, skipping releases younger than seven days, the same delay bun and pnpm use.

### Online workflow audits

zizmor's online audits (impostor commits, ref confusion, known-vulnerable actions, stale refs) resolve action references against the GitHub API, so they need network and a token, which flake checks cannot have. `nix run .#lint` runs them on `.github` after the flake checks, using `$GH_TOKEN` or `$GITHUB_TOKEN`, or else `gh auth token`. CI passes the job's `secrets.GITHUB_TOKEN` as `GITHUB_TOKEN` (Actions does not export it to steps on its own); the workflow's empty `permissions` still let it read the public action repositories the audits query.
