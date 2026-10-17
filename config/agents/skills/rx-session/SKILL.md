---
name: rx-session
description:
  Write, update, export, and debug named Rex session definition files for the
  `rx` launcher. Use when asked to create an rx session, convert the current Rex
  session into a reusable file, change a layout under `rex/sessions`, or decide
  whether a window belongs in a definition or `rx/shared.lua`.
---

# Write rx session files

## Start with the current implementation

Read the active implementation before you write a definition. In the dotfiles
repository, the launcher is `config/zsh.d/zsh/bin/rx`,
`config/rex/sessions/README.md` documents the contract, and
`config/rex/rx/shared.lua` holds the windows every new session gets. The script
is the source of truth if the documentation differs.

`rx` is the Rex counterpart of `mx`. Use the `rex` skill for general Rex CLI
work; this skill covers only `rx` definitions.

`rx <name>` looks for a session labeled `<name>` first. When one exists, `rx`
opens it and ignores the definition. Otherwise it loads `<name>.lua` with
`dofile` inside `rex do`, appends the windows from `shared.lua`, and builds all
windows in one `session.create` call. A definition that raises an error creates
no session. Without a definition, `rx <name>` creates a plain session labeled
`<name>` at `$PWD`. Plain `rx` labels the session with the basename of `$PWD`
and never loads a definition.

## Export an existing Rex session

Prefer `rx --export` to rebuilding a live session by hand. It reads the current
Rex session by default. Pass a session when you copy another session or run
outside Rex:

```bash
rx --export
rx --export source-session
```

The command writes the Lua definition to stdout. Redirect it to a temporary file
for review, or directly to the chosen destination:

```bash
tmp="$(mktemp)"
rx --export >"$tmp"
rx --export source-session > config/rex/sessions/new-session.lua
```

Check whether the destination exists before you redirect, because shell
redirection overwrites files. When the installed command is older than the
checkout, run `config/zsh.d/zsh/bin/rx --export` with the same arguments.

The export keeps window labels, the tiled split tree with its ratios, block
flavors, each block's directory, and the foreground commands that the zsh hook
in `config/zsh.d/zsh/config/extras.zsh` records. It omits the windows from
`shared.lua`, because `rx` appends them itself, and floating layers, which it
marks with a comment. It leaves out the recorded command of the block that runs
the export, so the definition does not rerun `rx --export`.

Rex reports only a process's name. A program started outside an integrated zsh,
or a command prefixed with a space, becomes a
`-- running <name> (command not recorded)` comment. Review every exported
command with the user, because arguments can contain secrets. Add or replace a
start command only when you know its full invocation. Do not read scrollback,
shell history, block contents, or process environments unless the user asks;
they can contain secrets and still may not show the original invocation.

Review the generated `root` and paths. The exporter uses the first block's
directory as `root`, writes directories under `root` as relative paths, writes
other paths under `$HOME` with `os.getenv("HOME")`, and leaves the rest
absolute. Replace transient directories with stable environment-based paths when
appropriate. Remove windows or blocks that are incidental and not part of the
intended startup layout.

## Choose the file and name

The filename is `<name>.lua`, and `<name>` becomes the session label exactly as
typed. Rex allows duplicate labels, but `rx` opens the first session with a
matching label, so choose a name that no unrelated session uses.

Choose the location by scope:

- Put machine-specific definitions in `$HOST_CONFIGS/rex/sessions/<name>.lua`.
  These are host-local and must not be committed.
- Put definitions shared by the dotfiles in `config/rex/sessions/<name>.lua`,
  which is installed at
  `${XDG_CONFIG_HOME:-$HOME/.config}/rex/sessions/<name>.lua`.
- `$HOST_CONFIGS` wins when both locations have the same name. Check for a
  shadowing host-local file before you change the tracked definition.

If the requested scope is unclear and the layout has machine-specific paths or
tools, ask which location to use.

## File contract

A definition is a Lua chunk that runs inside `rex do`, so the whole
[`rex` Lua API](https://www.superlogical.com/rex/docs/reference/lua.md) and
`os.getenv` are available. Rex has no `os.execute` or `io.popen`; use
`rex.exec { argv }` for probes, as `shared.lua` does.

The chunk returns a table with these keys only:

- `root`: the session directory. If omitted, `rx` uses the caller's `$PWD`.
- `windows`: a list of `{ label = <string>, layout = <rex.layout> }`. `label` is
  optional. An empty or missing list gives one shell window.

Keep the chunk free of side effects. Do not create, select, or attach sessions,
call `session.create`, or append the shared windows; `rx` owns that lifecycle.
Use `local` for helpers and values.

## Layout rules

Build layouts from `rex.layout.block { flavor = ..., options = { ... } }` and
the split constructors `rex.layout.horizontal(ratio, before, after)` and
`rex.layout.vertical(ratio, before, after)`. `ratio` is the share of the
`before` side. Use `com.superlogical.terminal.shell` as the flavor for shell
blocks.

A block without `cwd` starts in `root`. A relative `cwd` resolves against
`root`, so use relative paths for directories inside the project. Use absolute
or `os.getenv`-based paths for everything else. Do not type `cd` into a block.

Start programs with `initial_input = 'cmd\n'`, not `command`. Rex types the text
into an interactive shell, like `mx`'s `send-keys`, so aliases work and the
block falls back to a shell when the program exits.

Keep session-specific windows in the definition. A window that every rx session
should get belongs in `config/rex/rx/shared.lua`, which appends mail, rss, HN,
dotfiles, and notes windows when their programs or directories exist. Rex cannot
link one window into several sessions, so each session gets its own copies.
Changing the shared windows affects every new session; edit `shared.lua` and the
sessions README together.

## Template for a new layout

Use `rx --export` when a live session already has the desired layout. Otherwise,
start from this shape and include only the requested windows and blocks:

```lua
local shell = 'com.superlogical.terminal.shell'

return {
	root = os.getenv 'HOME' .. '/src/example',
	windows = {
		{
			label = 'editor',
			layout = rex.layout.horizontal(
				0.7,
				rex.layout.block {
					flavor = shell,
					options = { initial_input = 'nvim\n' },
				},
				rex.layout.block { flavor = shell }
			),
		},
		{
			label = 'server',
			layout = rex.layout.block {
				flavor = shell,
				options = { cwd = 'server', initial_input = './run-server\n' },
			},
		},
	},
}
```

## Validate without disrupting Rex

Check formatting with the repository's StyLua configuration. Pass it explicitly,
because StyLua finds no configuration for files outside the checkout, such as
host-local definitions:

```bash
session_file=/path/to/session-file.lua
stylua --check --config-path "$DOTFILES/.stylua.toml" "$session_file"
```

Then load the definition the way `rx` does, without creating a session. This
runs the chunk on the Rex server, so it also runs any `rex.exec` probes in the
definition:

```bash
RX_DEF="$session_file" rex do - <<'EOF'
local def = os.getenv("RX_DEF")
local spec = dofile(def)
if type(spec) ~= "table" then error(def .. ": must return a table", 0) end
local labels = {}
for i, w in ipairs(spec.windows or {}) do
	if type(w.layout) ~= "table" then error(def .. ": window " .. i .. " has no layout", 0) end
	labels[i] = w.label or ""
end
return { root = spec.root or "$PWD", windows = labels }
EOF
```

Confirm which file wins lookup without launching it:

```bash
for f in "${HOST_CONFIGS:+$HOST_CONFIGS/rex/sessions/new-session.lua}" \
	"${XDG_CONFIG_HOME:-$HOME/.config}/rex/sessions/new-session.lua"; do
	if [ -f "$f" ]; then
		printf '%s\n' "$f"
		break
	fi
done
```

Do not use `rx <name>` as a syntax test. It creates a session on the live server
and switches the app to it, or attaches the terminal outside Rex. An existing
session with the same label skips the definition entirely. Never close an
existing Rex session just to reload a changed definition unless the user
explicitly approves that destructive step.
