#!/usr/bin/env bash
set -ue -o pipefail

# Aggregates user prompts into a project-level PROMPTS.md file

# Only process UserPromptSubmit events
EVENT_TYPE="${1:-unknown}"
if [ "$EVENT_TYPE" != "UserPromptSubmit" ]; then
	exit 0
fi

# Use project directory if available
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
	# No project directory, skip
	exit 0
fi

# Validate project directory - no path traversal
if [[ "$CLAUDE_PROJECT_DIR" == *".."* ]]; then
	echo "Error: Invalid project directory path" >&2
	exit 0
fi

PROMPTS_FILE="$CLAUDE_PROJECT_DIR/PROMPTS.md"

# Read input from stdin
input=$(cat)

# If input is empty, exit
if [ -z "$input" ]; then
	exit 0
fi

# Extract the prompt text from the JSON input
# The UserPromptSubmit event should contain the prompt text
prompt_text=$(echo "$input" | jq -r '.prompt // empty')

# If no prompt text found, exit
if [ -z "$prompt_text" ]; then
	exit 0
fi

# Create or append to PROMPTS.md
if [ -f "$PROMPTS_FILE" ]; then
	# File exists, append with separator
	echo -e "\n\n---\n" >>"$PROMPTS_FILE"
	echo "$prompt_text" >>"$PROMPTS_FILE"
else
	# New file, just write the prompt
	echo "$prompt_text" >"$PROMPTS_FILE"
fi

# Don't block any operations
exit 0
