# Session definitions

Named session definitions for [`mx`](../../zsh.d/zsh/bin/mx). `mx <name>` looks up `$HOST_CONFIGS/tmux/sessions/<name>` first (host-local, not committed), then this directory (symlinked to `$XDG_CONFIG_HOME/tmux/sessions/`).

`mx --export [session]` prints a starting definition from the current or named tmux session; redirect stdout to the desired file. It omits linked `_shared` windows, preserves pane directories and layouts, and writes current process names as comments for manual review because tmux cannot recover the original command arguments.

A definition is a plain bash file, `source`d by `mx` — no shebang or executable bit needed. It may set `MX_ROOT=<dir>` (the session's working directory) and define `mx_start()`, which `mx` calls synchronously right after creating the detached session, with cwd `$MX_ROOT` and `MX_SESSION`/`MX_ROOT` exported.

Rules for `mx_start()`:

- Every tmux command must use explicit targets built from `$MX_SESSION` (e.g. `-t "=$MX_SESSION:mywindow"`). When `mx` runs from inside tmux, unqualified targets resolve against the caller's session, not the new one.
- Use `-c <dir>` on `new-window`/`split-window` instead of `send-keys "cd ..."`.
- Definition windows are created before `_shared` is linked, so they remain contiguous and take priority in the window order. After `mx_start` returns, the available shared windows are appended in `mail`, `rss`, `HN`, `dotfiles`, `notes` order.
- `mx_start` runs with errexit suppressed: a failing command does not abort the layout, and `mx` still attaches afterwards (a failure is reported via stderr and the tmux status line).
- Do not set variables other than `MX_ROOT` or define functions other than `mx_start` — the file is sourced into `mx`'s namespace.

Example:

```bash
MX_ROOT="$PROJECTS/work/acme/app"

mx_start() {
	tmux rename-window -t "=$MX_SESSION:1" "app"
	tmux split-window -h -l 30% -t "=$MX_SESSION:1" -c "$MX_ROOT"

	tmux new-window -t "=$MX_SESSION:" -n "api" -c "$MX_ROOT/../api"
	tmux send-keys -t "=$MX_SESSION:api.1" "$EDITOR" C-m

	tmux select-window -t "=$MX_SESSION:1"
}
```
