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

# Read JSON from stdin, extract all values, and do all number/cost/duration
# formatting in the single jq call so the render path forks no awk/sed/basename
{
	read -r model
	read -r context_percent
	read -r current_dir_full
	read -r current_dir
	read -r added_display
	read -r removed_display
	read -r duration_display
	read -r cost_display
} < <(jq -r '
	def commafy:
		tostring as $s | ($s | length) as $l
		| if $l <= 3 then $s
			else ($s[0:$l-3] | tonumber | commafy) + "," + $s[$l-3:]
			end;

	def fixed1:
		((. * 10 | round) / 10 | tostring)
		| if test("\\.") then . else . + ".0" end;

	def money($n):
		(. * pow(10; $n) | round | tostring) as $s | ($s | length) as $l
		| if $l <= $n then "$0." + (("0" * ($n - $l)) // "") + $s
			else "$" + $s[0:$l-$n] + "." + $s[$l-$n:]
			end;

	(.context_window.context_window_size // 200000) as $size
	| (if .context_window.current_usage then
			(.context_window.current_usage.input_tokens +
			 .context_window.current_usage.cache_creation_input_tokens +
			 .context_window.current_usage.cache_read_input_tokens)
		else 0 end) as $tokens
	| (.cost.total_lines_added) as $added
	| (.cost.total_lines_removed) as $removed
	| (.cost.total_duration_ms) as $ms
	| (.cost.total_cost_usd // 0) as $cost
	| .model.display_name,
		($tokens * 100 / $size | floor),
		.workspace.current_dir,
		(.workspace.current_dir | sub(".*/"; "")),
		(if $added > 0 then "+" + ($added | commafy) else "" end),
		(if $removed > 0 then "-" + ($removed | commafy) else "" end),
		(if $ms >= 3600000 then ($ms / 3600000 | fixed1) + "h"
		 elif $ms >= 60000 then ($ms / 60000 | fixed1) + "m"
		 elif $ms >= 1000 then ($ms / 1000 | fixed1) + "s"
		 else ($ms | tostring) + "ms" end),
		(if $cost <= 0 then ""
		 elif $cost < 0.01 then $cost | money(4)
		 elif $cost < 1 then $cost | money(3)
		 else $cost | money(2) end)
')

# Build context progress bar (15 chars wide)
bar_width=15
filled=$((context_percent * bar_width / 100))
empty=$((bar_width - filled))
bar=""
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done

# Build context bar display
context_info="${bar} ${context_percent}%"

# One git spawn per render: an empty result covers both "not a repo" and
# "detached HEAD", which is all the dropped rev-parse gate distinguished
git_branch=$(command git -C "$current_dir_full" branch --show-current 2>/dev/null)

output="/$current_dir"
output+=" ($git_branch) ${GRAY}|${NC}"
output+=" $model"

if [ -n "$added_display" ]; then
	output+=" ${GREEN}${added_display}${NC}"
fi

if [ -n "$removed_display" ]; then
	output+=" ${RED}${removed_display}${NC}"
fi

output+=" in ${duration_display}"

if [ -n "$cost_display" ]; then
	output+=" for ${cost_display}"
fi

output+=" ${GRAY}|${NC} $context_info"

echo -e "$output"
