# mx

`mx` opens a named session in tmux or Rex, and first creates the session if it does not exist yet. A session can come from a project directory under `$PROJECTS` or from a session definition, and the same definition works in both.

```sh
mx                  # session for $PWD (name = basename of $PWD)
mx <name>           # definition <name>.lua, else a project matching <name>, else $PWD
mx --dir <path>     # plain session rooted exactly at <path>
mx --list           # session and project candidates as TSV
mx --pick [query]   # fuzzy-pick a candidate and open it (Ctrl-G in zsh, prefix-g in tmux)
mx --export [name]  # print a definition based on a running session
mx --migrate        # convert old tmux and rx definitions to Lua
```

## Backends

`mx` uses Rex inside a Rex terminal (`REX_SESSION` set). It uses tmux inside tmux, including tmux that runs in a Rex terminal, and everywhere else. `rex attach` only shows a session and does not send keys, so Rex cannot take over a terminal the way `tmux attach` does. Set `MX_BACKEND=tmux` or `MX_BACKEND=rex` to choose one.

| | tmux | Rex |
| --- | --- | --- |
| Session name | `.` and `:` become `_` | the same name, used as the label |
| An existing session | `switch-client` (inside tmux) or `attach` | `session.select` in the Rex app, which needs Remote Control turned on |
| Shared windows | built once in `_shared` and linked into each session | copied into each session, because Rex cannot show one window in several sessions |
| An emptied session | not possible: tmux removes a session with no windows | Rex keeps it, so `mx` builds its windows again |
| `--pick` | an fzf popup | fzf inline, at 40% height |
| Floating layers | none in tmux | not exported; `--export` notes them in a comment |

Rex allows duplicate labels. `mx` opens the first session with a matching label, so pick names that no unrelated session uses.

The package holds `bin/mx`, `bin/mx-init` (builds the `_shared` tmux session), and the Lua code in `share/mx/`: `lib.lua` (shared), `tmux.lua` (run with LuaJIT), `rex.lua` (run inside `rex do`), and `migrate.lua`. `luajit` comes with the package. `tmux` and `rex` come from your `PATH`, so a client always matches its running server.

## Projects

Project directories are listed per root under `$PROJECTS`. `mx <name>` matches a label exactly or by a unique `/<name>` suffix, so `mx git-wt` and `mx c/master` work from anywhere.

| Root                                         | Rule                                                                                                                 |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `personal`, `trunk`, `forks`, `ahmedelgabri` | every direct subdirectory                                                                                            |
| `work`                                       | `work/<org>/<project>`; `.bare` projects also list child worktrees (subdirs with a `.git` entry)                     |
| `archive`                                    | project children (`.git`/`.bare`/`.jj`) are leaves; other children are grouping dirs whose child dirs are candidates |

Session names are derived from the picked directory (`.` and `:` become `_`):

| Picked dir                                | Session name                 |
| ----------------------------------------- | ---------------------------- |
| `trunk/X`, `personal/X`, `ahmedelgabri/X` | `X`                          |
| `work/<org>/<p>`                          | `<p>`                        |
| `work/<org>/<p>/<wt>`                     | `<p>/<wt>` (e.g. `c/master`) |
| `forks/X`                                 | `forks/X`                    |
| `archive/...`                             | `archive/...`, in full       |

Inside tmux, `mx` ends with `switch-client`. From a `run-shell` binding, tmux picks the "current client" by best match, which is correct when one client is attached.

## Session definitions

`mx <name>` looks up `$HOST_CONFIGS/mx/sessions/<name>.lua` first (host-local, not committed), then `${XDG_CONFIG_HOME:-~/.config}/mx/sessions/<name>.lua`. The file name without `.lua` is the session name, with `.` and `:` changed to `_` for tmux.

A definition is a Lua 5.1 file that returns plain data:

```lua
return {
	root = os.getenv 'PROJECTS' .. '/work/acme/app',
	windows = {
		{
			label = 'app',
			layout = {
				split = 'horizontal',
				ratio = 0.7,
				{ command = 'nvim', focus = true },
				{},
			},
		},
		{ label = 'api', layout = { cwd = '../api' } },
	},
}
```

- `root`: the session's directory. The default is `$PWD`.
- `windows`: a list of `{ label = <string>, layout = <node> }`. Without a `label`, the window gets tmux's automatic name. Without any windows, the session gets one shell at `root`.
- A pane node is `{ cwd = <dir>, command = <string>, focus = true }`, and every field is optional. A pane without `cwd` starts in `root`, and a relative `cwd` is resolved against `root`.
- `command` is typed into the pane's shell and followed by Enter, so aliases work, and the pane falls back to a shell when the program exits.
- `focus = true` makes the pane the active one in its window.
- A split node is `{ split = 'horizontal' | 'vertical', ratio = <0..1>, <first>, <second> }`. `horizontal` puts the two sides next to each other, and `vertical` stacks them. `ratio` is the first side's share and defaults to 0.5. To place three panes side by side, nest splits.
- The global `mx` has two helpers for conditions: `mx.has(cmd)` checks that a program is on `PATH`, and `mx.isdir(path)` checks that a directory exists.

`mx` reads the whole definition before it creates anything. A definition that fails to load or has a bad shape creates no session, and the error names the file and the bad field.

## Shared windows

`${XDG_CONFIG_HOME:-~/.config}/mx/shared.lua` ([`config/mx/shared.lua`](../../../config/mx/shared.lua)) uses the same format, without `root`. It lists the windows that every new session gets after its own windows: mail, rss, HN, dotfiles, and notes. Each one is added only when its program or directory exists. In tmux, `mx-init` builds them once in a `_shared` session, and `mx` links them into each new session in the same order. In Rex, each session gets its own copies.

## Export

`mx --export [name]` prints a definition for the current or the named session. Redirect the output to a file under one of the session directories. The export keeps window labels, the split tree with ratios, pane directories (relative to the first pane's directory, which becomes `root`), the active pane, and recorded commands. Shared windows are not exported. Rebuilding an export at the same window size gives the same pane geometry, and the output is already formatted the way `stylua` formats it.

tmux and Rex only report a process's name. To keep the exact commands, a zsh hook in [`extras.zsh`](../../../config/zsh.d/zsh/config/extras.zsh) writes the running command to `${XDG_STATE_HOME:-~/.local/state}/mx/commands/<pane>` and deletes it at the next prompt. `<pane>` is `tmux-<server pid>-<pane id>` in tmux and the block id in Rex. A command started outside an integrated zsh, or with a leading space, becomes a `-- running <process>` comment. Review the exported commands for secrets before you save the file.

## Migrating old definitions

`mx --migrate` converts the old definitions in `$HOST_CONFIGS/{tmux,rex}/sessions/` and `~/.config/{tmux,rex}/sessions/` to `<same place>/mx/sessions/<name>.lua`. It does not need Rex or your tmux server.

Old `rx` definitions (`<name>.lua` built with `rex.layout`) are loaded with a stand-in `rex.layout`, which returns mx nodes, and `initial_input` becomes `command`.

For old tmux definitions (bash files with `mx_start()`): `mx --migrate` runs each definition's `mx_start` against a private, temporary tmux server, with `/bin/sh` in every pane. It records each `send-keys` as that pane's command instead of typing it, then exports the result. Nothing in the definition runs in your own tmux server or shell.

The old files stay where they are. A name that already has a `.lua` file is skipped and reported; when a tmux and an rx definition share a name, the tmux one is converted first. Values from the environment, such as `$EDITOR` or `$DOTFILES`, are written as they were when the migration ran. A program that a definition started as the pane's own command (`new-window ... 'htop'`), rather than with `send-keys`, becomes a `-- running` comment.

## Tests

`nix build .#checks.<system>.mx` runs [`tests/mx.sh`](tests/mx.sh) against the built package. To run it from a checkout:

```sh
nix build .#mx && MX_BIN=$PWD/result/bin bash nix/pkgs/mx/tests/mx.sh
```

The suite starts a real tmux server on a private socket in a temporary directory, so it never touches your tmux server. It builds a `$PROJECTS` tree and session directories, and then checks:

- usage errors, `--list` output, and which definition wins
- name resolution and ambiguity, and session naming
- building `_shared` from the real `shared.lua` and linking its windows
- loading definitions, including a broken one, and the pane geometry, directories, and focus they produce
- byte-exact `--export` output, including commands with newlines and non-ASCII text, and leaving out the pane that runs the export
- a round trip that opens an exported definition and compares its geometry with the original, and checks that recorded commands replay in the right panes
- `--migrate` output, skipping definitions that were already converted, and that it starts no extra session and runs none of the definition's commands
- which backend runs: `MX_BACKEND` validation, and tmux inside a Rex terminal still uses tmux

`PATH` holds only the tools the scripts need, so `shared.lua` never starts the host's mail, RSS, or HN clients. Nothing is attached, so every launch ends with tmux's expected `no current client` error, which the suite checks. `--pick` is not covered because it needs an interactive fzf.

The Rex backend needs the Rex app, which is not in nixpkgs, so it has a live test with no Nix check:

```sh
nix build .#mx && MX_BIN=$PWD/result/bin bash nix/pkgs/mx/tests/live-rex.sh
```

It starts a real Rex server on a private socket, and every `rex` call goes through a wrapper that pins `-S` to that socket. It checks:

- plain sessions and reusing them
- definition layouts: split directions, ratios, directories, typed commands, and focus, with the first window active
- `$HOST_CONFIGS` priority, shared windows, and that broken definitions create no session
- refilling a session that has no windows
- attaching through `script`
- byte-exact `--export` output, including recorded commands, process comments, and leaving out the block that runs the export
- a round trip that opens the exported definition
- migrating an `rx` definition and opening the result

`session.select`, which `mx` uses inside Rex, is not covered because it needs the app with Remote Control turned on.
