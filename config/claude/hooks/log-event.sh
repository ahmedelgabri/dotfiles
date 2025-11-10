#!/usr/bin/env bash
set -ue -o pipefail

# Universal hook logger - logs all hook events to a JSONL file

# Use project directory if available, otherwise home directory
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
	# Validate project directory - no path traversal
	if [[ "$CLAUDE_PROJECT_DIR" == *".."* ]]; then
		echo "Error: Invalid project directory path" >&2
		exit 0
	fi
	LOG_FILE="$CLAUDE_PROJECT_DIR/.claude/hook-events.jsonl"
	# Ensure .claude directory exists
	mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
else
	LOG_FILE="$HOME/.claude/hook-events.jsonl"
	mkdir -p "$HOME/.claude"
fi

EVENT_TYPE="${1:-unknown}"

# Read all input from stdin
# Claude Code sends JSON data to hooks via stdin
input=$(cat)

# If input is empty, use empty object
if [ -z "$input" ]; then
	input_json="{}"
else
	# Validate input is valid JSON
	if echo "$input" | jq empty 2>/dev/null; then
		# Valid JSON - use as is
		input_json="$input"
	else
		# Not valid JSON - wrap as string
		input_json=$(jq -n --arg raw "$input" '{raw_input: $raw}')
	fi
fi

# Create log entry with timestamp
timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
log_entry=$(jq -n \
	--arg ts "$timestamp" \
	--arg event "$EVENT_TYPE" \
	--arg project_dir "${CLAUDE_PROJECT_DIR:-}" \
	--argjson input "$input_json" \
	'{
    timestamp: $ts,
    event: $event,
    project_dir: $project_dir,
    input: $input
  }')

# Append to log file (quoted variable)
echo "$log_entry" >>"$LOG_FILE"

# Don't block any operations
exit 0
