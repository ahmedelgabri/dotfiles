---
name: mx-session
description:
  Write, update, export, migrate, and debug named session definition files for
  the `mx` launcher. Use when asked to create an mx session, convert the
  current session into a reusable file, change a layout under `mx/sessions`,
  convert old tmux session files, or decide whether a window belongs in a
  definition or `shared.lua`.
---

# Write mx session files

## Start with the current implementation

Read the active implementation before writing a definition. In the dotfiles repository, `mx` is a package in `nix/pkgs/mx/`: the `mx` and `mx-init` scripts, plus `lua/lib.lua` (loading, checking, and writing definitions) and `lua/tmux.lua` (building and exporting tmux sessions). `nix/pkgs/mx/README.md` documents the contract. If the documentation and the code differ, trust the code.

## Export an existing session

Prefer `mx --export` over rebuilding a live session by hand. With no argument it reads the current session. Pass a session name to copy another session, or when you run it outside tmux:

```bash
mx --export
mx --export source-session
```

The command prints the Lua definition to stdout. Redirect it to a temporary file for review, or straight to the chosen destination:

```bash
tmp="$(mktemp)"
mx --export >"$tmp"
mx --export source-session > ~/.config/mx/sessions/new-session.lua
```

Shell redirection overwrites files, so check whether the destination exists first. In the dotfiles repository, before the installed package has been rebuilt, run `nix build .#mx` and use `result/bin/mx` with the same arguments.

The export keeps:

- window labels
- the split tree, with ratios
- pane directories
- the active pane in each window
- foreground commands recorded by the zsh integration

It leaves out the linked shared windows, because `mx` adds them itself. A command started outside an integrated zsh, or with a leading space, becomes a `-- running <process>` comment, because tmux cannot recover its arguments.

Review every exported command with the user, because arguments can contain secrets. Add or replace a restart command only when you know its full invocation. Do not inspect scrollback, shell history, pane contents, or pane environments unless the user asks. They can contain secrets, and they still may not show the original invocation reliably.

Review the generated `root` and paths. The exporter uses the first pane's directory as `root`. It writes paths inside `root` as relative paths and paths under `$HOME` with `os.getenv 'HOME'`, and leaves other paths absolute. Replace temporary directories with stable environment-based paths where that makes sense. Remove windows or panes that are incidental rather than part of the intended startup layout.

## Migrate old definitions

Old bash definitions (`MX_ROOT` plus `mx_start()`) in `$HOST_CONFIGS/tmux/sessions/` or `~/.config/tmux/sessions/` convert with `mx --migrate`. It writes `<name>.lua` into the matching `mx/sessions/` directory and skips names that already have one. It runs `mx_start` against a private tmux server and records `send-keys` instead of running them. After migrating, review the output like an export: environment values such as `$EDITOR` are written as they were during the migration.

## Choose the file and name

`mx <name>` looks for `<name>.lua`. The name becomes the session name, with `.` and `:` changed to `_` for tmux.

Choose the location by scope:

- Put machine-specific definitions in `$HOST_CONFIGS/mx/sessions/<name>.lua`. These are host-local and must not be committed.
- Put definitions shared by every host in `config/mx/sessions/<name>.lua`, which is installed at `${XDG_CONFIG_HOME:-$HOME/.config}/mx/sessions/<name>.lua`.
- When both locations hold the same name, `$HOST_CONFIGS` wins. Check for a shadowing host-local file before you change the tracked definition.

If the scope is unclear and the layout has machine-specific paths or tools, ask which location to use.

## File contract

A definition is a Lua 5.1 file that returns a table:

- `root`: the session directory. If omitted, `mx` uses the caller's current directory.
- `windows`: a list of `{ label = <string>, layout = <node> }`.
- A pane is `{ cwd = <dir>, command = <string>, focus = true }`, all optional. A relative `cwd` resolves against `root`. `command` is typed into the shell and followed by Enter.
- A split is `{ split = 'horizontal' | 'vertical', ratio = <0..1>, <first>, <second> }`. `horizontal` means side by side. To get more than two panes, nest splits.
- Conditions can use `mx.has(cmd)` and `mx.isdir(path)`.

Keep a definition as data. It runs whenever `mx` opens it, so it must not start programs or write files. Do not create sessions, link shared windows, or switch clients. `mx` owns that lifecycle.

Definition windows come first. `mx` then appends the shared windows from `shared.lua`, and selects the first window. A window that every session should have belongs in `config/mx/shared.lua`, not in a definition.

## Template for a new layout

Use `mx --export` when a live session already has the layout. Otherwise start from this shape, and include only the requested windows and panes:

```lua
return {
	root = os.getenv 'HOME' .. '/src/example',
	windows = {
		{
			label = 'editor',
			layout = {
				split = 'horizontal',
				ratio = 0.7,
				{ command = 'nvim', focus = true },
				{},
			},
		},
		{
			label = 'server',
			layout = { command = './run-server' },
		},
	},
}
```

## Validate without disrupting tmux

Check formatting:

```bash
stylua --config-path ~/.dotfiles/.stylua.toml --check /path/to/session.lua
```

Check which file wins the lookup without launching anything:

```bash
mx --list | awk -F '\t' -v name='new-session' '$1 == "sess" && $2 == name'
```

To see what a definition builds, open it on a private tmux server, for example with `TMUX_TMPDIR=$(mktemp -d)`, and with `TMUX` unset. Do not use `mx <name>` on the real server as a test: it attaches or switches the current client, and an existing session skips the definition entirely. Never kill an existing session just to reload a changed definition unless the user explicitly approves that step.
