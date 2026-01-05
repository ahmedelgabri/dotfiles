#!/usr/bin/env bash

# See: https://anthropic.mintlify.app/en/docs/claude-code/statusline

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Read JSON from stdin and extract all values in one jq call
{
	read -r model
	read -r context_size
	read -r current_tokens
	read -r current_dir_full
	read -r added
	read -r removed
	read -r total_duration
	read -r cost
} < <(cat | jq -r '
	.model.display_name,
	(.context_window.context_window_size // 200000),
	(if .context_window.current_usage then
		(.context_window.current_usage.input_tokens +
		 .context_window.current_usage.cache_creation_input_tokens +
		 .context_window.current_usage.cache_read_input_tokens)
	else 0 end),
	.workspace.current_dir,
	.cost.total_lines_added,
	.cost.total_lines_removed,
	.cost.total_duration_ms,
	(.cost.total_cost_usd // 0)
')

# Get directory basename for display
current_dir=$(basename "$current_dir_full")

# Calculate context percentage
context_percent=$((current_tokens * 100 / context_size))

# Build context progress bar (15 chars wide)
bar_width=15
filled=$((context_percent * bar_width / 100))
empty=$((bar_width - filled))
bar=""
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done

# Build context bar display
context_info="${bar} ${context_percent}%"

format_cost() {
	local cost_usd=$1
	awk -v cost="$cost_usd" 'BEGIN {
		if (cost < 0.01)
			printf "$%.4f", cost
		else if (cost < 1)
			printf "$%.3f", cost
		else
			printf "$%.2f", cost
	}'
}

format_duration() {
	local ms=$1
	awk -v ms="$ms" 'BEGIN {
		if (ms >= 3600000)
			printf "%.1fh", ms / 3600000
		else if (ms >= 60000)
			printf "%.1fm", ms / 60000
		else if (ms >= 1000)
			printf "%.1fs", ms / 1000
		else
			printf "%dms", ms
	}'
}

# Format lines with thousand separators (portable version)
format_lines() {
	printf "%d" "$1" | sed ':a;s/\B[0-9]\{3\}\>/,&/;ta'
}

git_branch=""
if command git -C "$current_dir_full" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	git_branch=$(command git -C "$current_dir_full" branch --show-current 2>/dev/null || echo "detached")
fi

output="/$current_dir"
output+=" ($git_branch) |"
output+=" $model"

if ((added > 0)); then
	output+=" ${GREEN}+$(format_lines "$added")${NC}"
fi

if ((removed > 0)); then
	output+=" ${RED}-$(format_lines "$removed")${NC}"
fi

output+=" in $(format_duration "$total_duration")"

if awk -v cost="$cost" 'BEGIN { exit !(cost > 0) }'; then
	output+=" for $(format_cost "$cost")"
fi

output+=" | $context_info"

echo -e "$output"
