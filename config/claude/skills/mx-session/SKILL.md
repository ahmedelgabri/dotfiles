---
name: mx-session
description:
  Write, update, export, and debug named tmux session definition files for the
  `mx` launcher. Use when asked to create an mx session, convert the current
  tmux session into a reusable file, change a layout under `tmux/sessions`, or
  decide whether a window belongs in an mx definition or `mx-init`.
---

# Write mx session files

## Start with the current implementation

Read the active implementation before writing a definition. In the dotfiles
repository, the source files are `config/zsh.d/zsh/bin/mx` and
`config/zsh.d/zsh/bin/mx-init`; `config/tmux/sessions/README.md` documents the
contract. Treat the scripts as the source of truth if the documentation differs.

`mx-init` does not load session definition files. It creates the `_shared`
session once. For each new named session, `mx` creates the session, calls that
definition's `mx_start` function, then appends any available shared windows.

## Export an existing tmux session

Prefer `mx --export` over reconstructing a live session by hand. It reads the
current tmux session by default; pass a source session when copying another
session or running outside tmux:

```bash
mx --export
mx --export source-session
```

The command writes the Bash definition to stdout. Redirect it to a temporary
file for review or directly to the chosen tracked or host-local destination:

```bash
tmp="$(mktemp)"
mx --export >"$tmp"
mx --export source-session > config/tmux/sessions/new-session
```

Check whether the destination already exists before redirecting because shell
redirection overwrites files. When working in the dotfiles repository before the
installed command has been updated, run `config/zsh.d/zsh/bin/mx --export` with
the same arguments instead.

The export preserves unlinked window names, pane counts, current pane
directories, serialized tmux layouts, and active panes. It omits linked windows
because `mx` appends `_shared` itself. It also omits running commands: tmux
exposes the current process name but cannot recover the original command and
arguments, so the exporter emits a comment for each pane instead of inventing a
`send-keys` command.

Review every exported command comment with the user. Add a restart command only
when its full invocation is known. Do not inspect scrollback, shell history,
pane contents, or pane environments unless the user asks; they can contain
secrets and still may not reveal the original invocation reliably.

Review the generated `MX_ROOT` and paths. The exporter chooses the first
unlinked pane's current directory as `MX_ROOT`, uses `$HOME` and `$MX_ROOT`
where possible, and leaves unrelated paths explicit. Replace transient
directories with stable environment-based paths when appropriate. Remove windows
or panes that are incidental rather than part of the intended startup layout.

## Choose the file and name

Use a filename with no extension unless the extension is intentionally part of
the command. `mx <name>` looks for that exact filename, and the filename becomes
the session name before `.` and `:` are changed to `_` for tmux.

Choose the location by scope:

- Put machine-specific definitions in `$HOST_CONFIGS/tmux/sessions/<name>`.
  These are host-local and must not be committed.
- Put definitions shared by the dotfiles in `config/tmux/sessions/<name>`, which
  is installed at `${XDG_CONFIG_HOME:-$HOME/.config}/tmux/sessions/<name>`.
- `$HOST_CONFIGS` wins when both locations contain the same name. Check for a
  shadowing host-local file before changing the tracked definition.

If the requested scope is unclear and the layout contains machine-specific paths
or tools, ask which location to use.

## File contract

A definition is a Bash fragment sourced by `mx` under `set -ue -o pipefail`. It
needs no shebang and should not be executable.

At top level, it may only:

- Assign `MX_ROOT`, the directory where `mx` creates the session and its first
  window. If omitted, `mx` uses the caller's current directory.
- Define `mx_start`, which builds the layout after the detached session exists
  and before shared windows are linked.

Do not run commands at source time, assign other top-level variables, or define
helper functions. They would share and could overwrite `mx`'s namespace. Put
temporary state in `local` variables inside `mx_start`. Quote expansions, and
account for nounset when using optional environment variables.

Do not create or attach the session, call `mx-init`, link shared windows, or
switch clients. `mx` owns that lifecycle.

## Layout rules

The first session window already exists at index 1 with cwd `$MX_ROOT`. Rename
or split it rather than creating a replacement.

Every tmux command in `mx_start` must have an explicit target based on
`$MX_SESSION`. This applies to `rename-window`, `new-window`, `split-window`,
`send-keys`, `select-pane`, `select-layout`, and any other tmux command that
accepts a target. Without the target, a call made from inside tmux can mutate
the caller's session.

Use exact targets with the leading `=`:

```bash
-t "=$MX_SESSION:1"
-t "=$MX_SESSION:server"
-t "=$MX_SESSION:server.1"
```

Use `-c <dir>` on `new-window` and `split-window`. Do not send `cd` through
`send-keys`.

Create auto-indexed windows with `-t "=$MX_SESSION:"`. Definition windows are
created first and stay contiguous. After `mx_start` returns, `mx` appends the
available shared windows in `mail`, `rss`, `HN`, `dotfiles`, `notes` order. Do
not rely on fixed indexes for shared windows because their indexes depend on the
number of definition windows and which shared programs are available.

`mx_start` runs synchronously with errexit suppressed so one failed layout
command does not stop later commands or strand the user outside tmux. Do not
rely on failure stopping the function. Keep dependent operations guarded when
needed. `mx` selects window 1 after it appends the shared windows, so selecting
another window in the definition will not determine the window shown on attach.
Use `select-pane` if a particular pane in window 1 should be active.

## Template for a new layout

Use `mx --export` when a live session already has the desired layout. Otherwise
start from this shape and include only the requested windows and panes:

```bash
MX_ROOT="$HOME/src/example"

mx_start() {
	tmux rename-window -t "=$MX_SESSION:1" "editor"
	tmux split-window -h -l 30% -t "=$MX_SESSION:1" -c "$MX_ROOT"

	tmux new-window -t "=$MX_SESSION:" -n "server" -c "$MX_ROOT"
	tmux send-keys -t "=$MX_SESSION:server.1" "./run-server" C-m

	tmux select-pane -t "=$MX_SESSION:1.1"
}
```

Use window names for later targets when possible. They are easier to read and do
not depend on indexes. Use a full pane target when sending commands.

Keep session-specific windows in the definition. A window that should be shared
by every mx session belongs in `_shared`; changing that requires coordinated
edits to `mx-init`, `link_shared_windows` in `mx`, and the session documentation
rather than a definition alone.

## Validate without disrupting tmux

Run syntax and static checks first:

```bash
session_file=/path/to/session-file
bash -n "$session_file"
shellcheck -s bash "$session_file"
```

If ShellCheck is unavailable, `bash -n` is the required minimum. Review every
tmux invocation for an explicit `"=$MX_SESSION..."` target and every new pane or
window for `-c` when its cwd matters.

Confirm which file wins lookup precedence without launching it:

```bash
mx --list | awk -F '\t' -v name='new-session' '$1 == "sess" && $2 == name'
```

Do not use `mx <name>` as a harmless syntax test. It attaches or switches the
current client, and an existing session skips both the definition and
`mx_start`. Never kill an existing tmux session merely to reload a changed
definition unless the user explicitly approves that destructive step.
