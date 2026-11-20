#!/bin/sh
# SessionStart hook for Claude Code and Codex: write the command that resumes
# this session to $_MX_RESUME_FILE, which the zsh in a Rex pane exports. After
# a Rex server restart the pane's new shell puts it on the prompt instead of
# the command that started the agent, which would open a new session. See the
# mx section of config/zsh.d/zsh/config/extras.zsh.
# Usage: mx-resume.sh claude|codex (the hook JSON arrives on stdin)

agent=${1-}
case $agent in
claude) resume='claude --resume' ;;
codex) resume='codex resume' ;;
*)
	echo "usage: mx-resume.sh claude|codex" >&2
	exit 64
	;;
esac

[ -n "${_MX_RESUME_FILE-}" ] && [ -n "${_MX_SHELL_PID-}" ] || exit 0

# Agents that another agent starts inherit the variable too, but only the one
# the pane's shell started owns the pane. The hook may run under a shell of
# its own, so look for the nearest agent process first.
pid=$PPID
# A process that exits mid-walk leaves pid empty, which ends the walk.
while [ "${pid:-0}" -gt 1 ] && [ "$(basename -- "$(ps -o comm= -p "$pid")")" != "$agent" ]; do
	pid=$(ps -o ppid= -p "$pid" | tr -d ' ')
done
[ "${pid:-0}" -gt 1 ] && [ "$(ps -o ppid= -p "$pid" | tr -d ' ')" = "$_MX_SHELL_PID" ] || exit 0

mkdir -p -- "$(dirname -- "$_MX_RESUME_FILE")"
jq -r --arg resume "$resume" '"cd -- \(.cwd | @sh) && \($resume) \(.session_id | @sh)"' >"$_MX_RESUME_FILE"
