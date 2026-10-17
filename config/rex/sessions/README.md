# Session definitions

Named session definitions for [`rx`](../../zsh.d/zsh/bin/rx), the Rex
counterpart of `mx`. `rx <name>` looks up
`$HOST_CONFIGS/rex/sessions/<name>.lua` first (host-local, not committed), then
this directory (symlinked to `$XDG_CONFIG_HOME/rex/sessions/`). Without a
definition, `rx <name>` creates a plain session labeled `<name>` at `$PWD`.

`rx` only creates a session when no session has that label yet; otherwise it
opens the existing one. Inside a Rex terminal it switches the app with
`session.select`, which needs Remote Control turned on in the app's settings.
Outside Rex it runs `rex attach`.

`rx --export [session]` prints a starting definition from the current or named
Rex session; redirect stdout to the desired file. It keeps window labels, the
split tree with its ratios, and each pane's directory (relative to the first
pane's directory, which becomes `root`). It omits the windows `shared.lua` adds
and floating layers. Rex reports only a process's name, so exact commands come
from a zsh hook in [`extras.zsh`](../../zsh.d/zsh/config/extras.zsh): in Rex
terminals it writes the running command to
`${XDG_STATE_HOME:-~/.local/state}/rx/commands/<block-id>` and deletes it at the
next prompt. Commands started outside an integrated zsh or prefixed with a space
stay as process-name comments. Review exported commands for secrets before
saving the definition.

A definition is a Lua file that `rx` loads with `dofile` inside `rex do`, so the
whole [`rex` Lua API](https://www.superlogical.com/rex/docs/reference/lua.md)
and `os.getenv` are available. It returns a table:

- `root`: the session's directory. Defaults to `$PWD`.
- `windows`: a list of `{ label = <string>, layout = <rex.layout> }`. `label` is
  optional.

Rules:

- A block without `cwd` starts in `root`; a relative `cwd` resolves against
  `root`.
- Start programs with the block option `initial_input = "cmd\n"`, not `command`.
  The text is typed into an interactive shell, like `mx`'s `send-keys`, so
  aliases work and the pane falls back to a shell when the program exits.
- `rx` builds every window in one `session.create` call. A definition that
  raises an error creates no session.
- After the definition's windows, `rx` appends the windows from
  [`../rx/shared.lua`](../rx/shared.lua) (mail, rss, HN, dotfiles, notes, each
  only when its program or directory exists). Rex cannot link a window into
  several sessions, so every session gets its own copies.

Example:

```lua
local shell = 'com.superlogical.terminal.shell'

return {
	root = os.getenv 'PROJECTS' .. '/work/acme/app',
	windows = {
		{
			label = 'app',
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
			label = 'api',
			layout = rex.layout.block {
				flavor = shell,
				options = { cwd = '../api' },
			},
		},
	},
}
```
