#!/usr/bin/env bash

# See: https://anthropic.mintlify.app/en/docs/claude-code/statusline

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
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

# A colocated jj repo also has a .git directory, so jj is tried first and its
# failure exit doubles as "not a jj repo". --ignore-working-copy keeps the
# statusline from snapshotting the working copy, which would race with the
# user's own jj commands. The revset and template are the `prompt_revs()` and
# `prompt_fields()` aliases in the jj config, shared with the shell prompt and
# the pi footer so all three render the same data. For git, an empty result
# covers both "not a repo" and "detached HEAD", which is all the dropped
# rev-parse gate distinguished
if jj_out=$(cd "$current_dir_full" 2>/dev/null && command jj log --ignore-working-copy --no-graph --color never \
	-r 'prompt_revs()' -T 'prompt_fields()' 2>/dev/null); then
	change=""
	dirty=""
	conflict=""
	workspace=""
	bookmarks=""
	while IFS= read -r line; do
		case "$line" in
		change=*) change="${line#change=}" ;;
		dirty=*) dirty="${line#dirty=}" ;;
		conflict=*) conflict="${line#conflict=}" ;;
		workspace=*) workspace="${line#workspace=}" ;;
		# A merge @ can have several nearest bookmarked ancestors, one line each
		bookmarks=*) bookmarks="${bookmarks:+$bookmarks,}${line#bookmarks=}" ;;
		esac
	done <<<"$jj_out"
	workspace="${workspace%@}"
	if [ "$workspace" = "default" ]; then
		workspace=""
	fi
	vcs_info="${workspace:+[$workspace] }${change}${dirty}${conflict:+${RED}✗${NC}}${bookmarks:+ $bookmarks}"
else
	vcs_info=$(command git -C "$current_dir_full" branch --show-current 2>/dev/null)
fi

output="/$current_dir"
output+=" ($vcs_info) ${GRAY}|${NC}"
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
