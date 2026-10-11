#!/usr/bin/env bash

# See: https://anthropic.mintlify.app/en/docs/claude-code/statusline

# Colors
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
GRAY=$'\033[0;90m'
NC=$'\033[0m' # No Color

# Read JSON from stdin, extract all values, and do all number/cost/duration
# formatting in the single jq call so the render path forks no awk/sed/basename
if ! fields=$(jq -ers --arg home "$HOME" '
	def nonnegative:
		if type == "number" and . >= 0 then . else error("invalid number") end;

	def single_line:
		if type == "string" and (test("[\u0000-\u001f\u007f]") | not)
		then . else error("invalid text") end;

	def commafy:
		tostring as $s | ($s | length) as $l
		| if $l <= 3 then $s
			else ($s[0:$l-3] | tonumber | commafy) + "," + $s[$l-3:]
			end;

	def fixed1:
		((. * 10 | round) / 10 | tostring)
		| if test("\\.") then . else . + ".0" end;

	def duration:
		if . >= 3600000 then (. / 3600000 | fixed1) + "h"
		elif . >= 60000 then (. / 60000 | fixed1) + "m"
		elif . >= 1000 then (. / 1000 | fixed1) + "s"
		else tostring + "ms" end;

	def token_count:
		if . >= 1000000 then ((. / 100000 | round) / 10 | tostring) + "M"
		elif . >= 1000 then ((. / 100 | round) / 10 | tostring) + "k"
		else tostring end;

	def money($n):
		(. * pow(10; $n) | round | tostring) as $s | ($s | length) as $l
		| if $l <= $n then "$0." + (("0" * ($n - $l)) // "") + $s
			else "$" + $s[0:$l-$n] + "." + $s[$l-$n:]
			end;

	if length == 1 and (.[0] | type == "object") then .[0]
	else error("expected one session object") end
	| (.context_window.context_window_size // 200000 | nonnegative
		| if . > 0 then . else error("zero context size") end) as $size
	| ((.context_window.current_usage.input_tokens // 0 | nonnegative) +
		 (.context_window.current_usage.cache_creation_input_tokens // 0 | nonnegative) +
		 (.context_window.current_usage.cache_read_input_tokens // 0 | nonnegative)) as $tokens
	| (.cost.total_lines_added // 0 | nonnegative | floor) as $added
	| (.cost.total_lines_removed // 0 | nonnegative | floor) as $removed
	| (.cost.total_duration_ms // 0 | nonnegative) as $ms
	| (.cost.total_api_duration_ms | if . == null then "" else nonnegative | duration end) as $api_duration
	| (.cost.total_cost_usd // 0 | nonnegative) as $cost
	| (.workspace.current_dir // "" | single_line) as $dir
	| (.model.display_name // "Claude" | single_line),
		($tokens * 100 / $size | floor),
		(($tokens | token_count) + "/" + ($size | token_count)),
		$dir,
		(if $dir == "" then "?"
		 elif $dir == $home then "~"
		 elif $dir | startswith($home + "/") then "~" + $dir[($home | length):]
		 else $dir end),
		(if $added > 0 then "+" + ($added | commafy) else "" end),
		(if $removed > 0 then "-" + ($removed | commafy) else "" end),
		($ms | duration),
		$api_duration,
		(if $cost <= 0 then ""
		 elif $cost < 0.01 then $cost | money(4)
		 elif $cost < 1 then $cost | money(3)
		 else $cost | money(2) end)
' 2>/dev/null); then
	printf '%s\n' 'statusline: invalid session data' >&2
	exit 1
fi

{
	IFS= read -r model
	IFS= read -r context_percent
	IFS= read -r tokens_display
	IFS= read -r current_dir_full
	IFS= read -r current_dir
	IFS= read -r added_display
	IFS= read -r removed_display
	IFS= read -r duration_display
	IFS= read -r api_duration_display
	IFS= read -r cost_display
} <<<"$fields"

# Claude captures stdout, so terminal ioctls cannot supply the display width.
compact=0
if [[ ${COLUMNS:-} =~ ^[0-9]{1,5}$ ]] && ((10#$COLUMNS > 0 && 10#$COLUMNS < 120)); then
	compact=1
fi

shorten_ref() {
	local ref=$1
	if ((${#ref} > 18)); then
		printf '%s…' "${ref:0:17}"
	else
		printf '%s' "$ref"
	fi
}

if ((compact)) && ((${#current_dir} > 24)); then
	current_dir="…${current_dir: -23}"
fi

# Build context progress bar
bar_width=15
if ((compact)); then bar_width=5; fi
filled=$((context_percent * bar_width / 100))
if ((filled > bar_width)); then filled=$bar_width; fi
empty=$((bar_width - filled))
bar=""
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done

# Build context bar display
context_color=""
if ((context_percent >= 90)); then
	context_color=$RED
elif ((context_percent >= 70)); then
	context_color=$YELLOW
fi
context_info="${context_color}${bar} ${context_percent}%${NC} ${tokens_display}"

# A colocated jj repo also has a .git directory, so jj is tried first and its
# failure exit doubles as "not a jj repo". --ignore-working-copy keeps the
# statusline from snapshotting the working copy, which would race with the
# user's own jj commands. The revset and template are the `prompt_revs()` and
# `prompt_fields()` aliases in the jj config, shared with the shell prompt and
# the pi footer so all three render the same data.
vcs_info=""
if [ -n "$current_dir_full" ] && jj_out=$(cd "$current_dir_full" 2>/dev/null && command jj log --ignore-working-copy --no-graph --color never \
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
	if ((compact)); then
		workspace=$(shorten_ref "$workspace")
		bookmarks=$(shorten_ref "$bookmarks")
	fi
	vcs_info="${workspace:+[$workspace] }${change}${dirty}${conflict:+${RED}✗${NC}}${bookmarks:+ $bookmarks}"
elif [ -n "$current_dir_full" ] && git_out=$(command git --no-optional-locks -C "$current_dir_full" \
	status --porcelain=v2 --branch --untracked-files=normal 2>/dev/null); then
	branch=""
	oid=""
	dirty=""
	conflict=""
	ahead=""
	behind=""
	while IFS= read -r line; do
		case "$line" in
		'# branch.head '*) branch="${line#\# branch.head }" ;;
		'# branch.oid '*) oid="${line#\# branch.oid }" ;;
		'# branch.ab '*)
			read -r _ _ ahead behind <<<"$line"
			ahead="${ahead#+}"
			behind="${behind#-}"
			if [ "$ahead" = "0" ]; then ahead=""; fi
			if [ "$behind" = "0" ]; then behind=""; fi
			;;
		'u '*)
			dirty="*"
			conflict="1"
			;;
		'1 '* | '2 '* | '? '*) dirty="*" ;;
		esac
	done <<<"$git_out"
	if [ "$branch" = "(detached)" ]; then branch="${oid:0:7}"; fi
	if ((compact)); then branch=$(shorten_ref "$branch"); fi
	vcs_info="${branch}${dirty}${conflict:+${RED}✗${NC}}${ahead:+ ↑$ahead}${behind:+ ↓$behind}"
fi

output="$current_dir"
output+="${vcs_info:+ ($vcs_info)} ${GRAY}|${NC}"
output+=" $model"

if ((! compact)); then
	if [ -n "$added_display" ]; then
		output+=" ${GREEN}${added_display}${NC}"
	fi

	if [ -n "$removed_display" ]; then
		output+=" ${RED}${removed_display}${NC}"
	fi

	output+=" in ${duration_display}${api_duration_display:+ (API $api_duration_display)}"

	if [ -n "$cost_display" ]; then
		output+=" for ${cost_display}"
	fi
fi

output+=" ${GRAY}|${NC} $context_info"

printf '%s\n' "$output"
