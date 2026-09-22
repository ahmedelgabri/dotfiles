# Pi extensions

Each extension lives in `<name>/index.ts`, with its documentation and other extension-specific files in the same directory. Pi discovers these entrypoints automatically. Shared helpers stay in `lib/`, and the common `package.json`, `tsconfig.json`, and Nix-managed `node_modules` stay at the extensions root. `lib/` has no entrypoint, so Pi does not load it as an extension.

The directory migration moves all 14 standalone entrypoints, colocates the [`/simplify` documentation](simplify/README.md), and adjusts relative imports without changing extension behavior. The [`/diff` extension](diff/README.md) already uses this layout.

## Extension reference

Each extension has a colocated README covering its usage, requirements, configuration, and state where applicable. These guides document the existing behavior; they do not change extension code. `lib/` contains shared code rather than an independently loaded extension.

| Extension | Commands, tools, or behavior |
| --- | --- |
| [answer](answer/README.md) | `/answer` and `Ctrl+.` extract questions into an interactive form |
| [atuin](atuin/README.md) | Record Bash tool calls in Atuin history |
| [diff](diff/README.md) | `/diff` opens browser reviews with annotation tools |
| [edit-answers](edit-answers/README.md) | `/edit-answer` and `Ctrl+Shift+V` edit the latest response externally |
| [jujutsu](jujutsu/README.md) | jj footer, Git-write guard, and `/jj-refresh` |
| [linear](linear/README.md) | Read-only `linear_graphql` tool with keychain credentials |
| [loop](loop/README.md) | `/loop` runs recurring tasks in detached tmux sessions |
| [mac-system-theme](mac-system-theme/README.md) | Follow macOS appearance with the plain themes |
| [md](md/README.md) | `/md` saves the latest assistant response as Markdown |
| [notify](notify/README.md) | Terminal notifications when the agent settles |
| [simplify](simplify/README.md) | `/simplify` runs four reviewers before parent-applied cleanup |
| [tap-agent-state](tap-agent-state/README.md) | Report Pi activity to tmux-agent-panel |
| [todos](todos/README.md) | `/todos` manager and file-backed `todo` tool |
| [total-cost](total-cost/README.md) | `/total-cost` summarizes recorded monthly session costs |
| [web-search](web-search/README.md) | `web_search` tool using Exa's hosted endpoint |

## Activation

Rebuild Home Manager before starting or reloading Pi after moving files. Home Manager links each file individually, so existing top-level extension symlinks point to missing files until the rebuild replaces them with directory entrypoints. For an explicit load, use `pi -e /path/to/extensions/<name>/index.ts`.

`tap-agent-state/index.ts` retains its upstream management notice. Check the layout after running `tap install`, which may recreate a top-level `tap-agent-state.ts` and cause duplicate registrations.

## Validation

Run `tsc -p config/pi/agent/extensions/tsconfig.json` from the repository root to check the extension imports and types.

The local, uncommitted tests under `scripts/tests/` cover the directory layout, relative imports, documentation links, type checking, and real Pi discovery through an isolated agent directory:

```sh
python3 scripts/tests/pi-extension-layout.test.py
bun test scripts/tests/pi-simplify.test.ts
bun test scripts/tests/pi-upgrade.test.ts
```

The discovery test starts the installed Pi CLI and checks registered commands, tools, and entrypoint paths without making model requests or mocking Pi APIs.
