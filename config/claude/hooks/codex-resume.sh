#!/bin/sh
# SessionStart hook for Codex: tell the terminal how to resume this session,
# so Rex starts `codex resume <id>` again after a server restart. Rex's own
# hook does this for Claude Code, but not yet for Codex.
# The hook JSON arrives on stdin.

[ -n "${OSC7577_TOKEN-}" ] || exit 0

# The report names the Codex process, which the terminal checks against the
# command. The hook may run under a shell of its own, so look for the nearest
# codex process.
pid=$PPID
# A process that exits mid-walk leaves pid empty, which ends the walk.
while [ "${pid:-0}" -gt 1 ] && [ "$(basename -- "$(ps -o comm= -p "$pid")")" != codex ]; do
	pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done
[ "${pid:-0}" -gt 1 ] || exit 0

jq -r '.cwd, .session_id' | {
	read -r cwd
	read -r id
	resume-report "$pid" "$cwd" codex resume "$id" >/dev/tty
}
