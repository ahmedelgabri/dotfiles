#!/usr/bin/env bash
set -ue -o pipefail

# https://www.reddit.com/r/ClaudeAI/comments/1oh95lh/claude_code_usage_limit_hack/
# One jq call on this blocking hook: parse stdin and test the command against
# the blocklist directly, with no cat/grep forks. Invalid or missing input
# falls through to "not blocked", matching the old non-blocking failure mode.
blocked=$(jq -r '(.tool_input.command // "") | test("node_modules/|\\.env|__pycache__/|(^|/)\\.git/|dist/|build/|\\.next/|\\.astro/|\\.vscode/|\\.idea/")' 2>/dev/null) || blocked=false

if [[ "$blocked" == "true" ]]; then
	echo "ERROR: Blocked directory pattern" >&2
	exit 2
fi
