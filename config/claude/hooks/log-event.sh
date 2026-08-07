#!/usr/bin/env bash
set -ue -o pipefail

# Universal hook logger - logs all hook events to a JSONL file

# Log centrally under ~/.claude/logs, keyed by project: a transcript of
# every prompt and tool input inside the project tree ships with archives,
# backups, docker build contexts, and rsync deploys — gitignore only
# protects the git channel. The slug matches Claude Code's own
# ~/.claude/projects encoding.
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
	# Validate project directory - no path traversal
	if [[ "$CLAUDE_PROJECT_DIR" == *".."* ]]; then
		echo "Error: Invalid project directory path" >&2
		exit 0
	fi
	LOG_DIR="$HOME/.claude/logs/${CLAUDE_PROJECT_DIR//[\/.]/-}"
else
	LOG_DIR="$HOME/.claude/logs"
fi
LOG_FILE="$LOG_DIR/hook-events.jsonl"
mkdir -p "$LOG_DIR"

EVENT_TYPE="${1:-unknown}"

# Read all input from stdin
# Claude Code sends JSON data to hooks via stdin
input=$(cat)

# Build and append the log entry in a single jq run: jq supplies the UTC
# timestamp, parses stdin as JSON when possible, and wraps anything else as
# a raw string, so no validation pass or date fork is needed.
jq -cn \
	--arg raw "$input" \
	--arg event "$EVENT_TYPE" \
	--arg project_dir "${CLAUDE_PROJECT_DIR:-}" \
	'{
    timestamp: (now | todate),
    event: $event,
    project_dir: $project_dir,
    input: (if $raw == "" then {} else ($raw | try fromjson catch {raw_input: $raw}) end)
  }' >>"$LOG_FILE"

# Don't block any operations
exit 0
