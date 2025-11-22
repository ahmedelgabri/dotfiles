#!/usr/bin/env bash
set -ue -o pipefail

# https://www.reddit.com/r/ClaudeAI/comments/1oh95lh/claude_code_usage_limit_hack/
COMMAND=$(cat | jq -r '.tool_input.command')
BLOCKED="node_modules|\.env|__pycache__|(^|/)\\.git/|dist/|build/|\.next|\.astro|\.vscode|\.idea"

if echo "$COMMAND" | grep -qE "$BLOCKED"; then
	echo "ERROR: Blocked directory pattern" >&2
	exit 2
fi
