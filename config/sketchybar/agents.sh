#!/usr/bin/env bash
# Shows one item per coding agent in every Rex session, named after its tab,
# with the state the agent reports to Rex (OSC 7501). Rex has no agent list,
# so every terminal pane with a program status record counts as an agent.

# Overlapping runs, such as an event right after the startup update, would
# both add the same new agent, so runs take turns.
if [[ -z "${AGENTS_LOCKED-}" ]]; then
	AGENTS_LOCKED=1 exec /usr/bin/lockf -k "${TMPDIR:-/tmp}/sketchybar-agents.lock" "$0" "$@"
fi

# shellcheck source=SCRIPTDIR/segments.sh
source "$(dirname "$0")/segments.sh"

rexq() { rex "$@" 2>/dev/null; }

# Prints one "<item>\t<state>\t<tab name>" row per agent, in Rex's tab order.
list_agents() {
	local session windows block window state name
	for session in $(rexq ls --json | jq -r '.sessions[].session_id'); do
		windows="$(rexq window ls -s "$session" --json)"
		while IFS=$'\t' read -r block window; do
			# The root record (no id) speaks for the whole program.
			state="$(rexq block call -s "$session" -b "$block" program_status |
				jq -r '(first(.records[] | select(.id == null)) // .records[0]).state // empty')"
			[[ -n "$state" ]] || continue
			name="$(jq -r --arg w "$window" '.windows[] | select(.window_id == $w) | .label' <<<"$windows")"
			# Rex names untitled tabs "Window <id>"; the agent's directory says more.
			if [[ "$name" =~ ^Window\ [0-9a-f]+$ ]]; then
				name="$(rexq block call -s "$session" -b "$block" process | jq -r '.foreground.cwd // empty')"
				name="${name##*/}"
			fi
			printf 'agent.%s\t%s\t%s\n' "${block#block:}" "$state" "$name"
		done < <(rexq block ls -s "$session" --json |
			jq -r '.blocks[] | select(.flavor | startswith("com.superlogical.terminal")) | [.block_id, .window_id] | @tsv')
	done
}

# Glyphs and colours match the agent markers in tmux's window-status-format;
# spinner.sh animates working agents from the first frame. Idle agents get no
# glyph.
glyph_and_color() {
	case "$1" in
	blocked | error) echo "▲ brightred" ;;
	done) echo "? yellow" ;;
	working) echo "${SPINNER_FRAMES[0]} cyan" ;;
	esac
}

agents="$(list_agents)"
shown="$(sketchybar --query bar | jq -r '.items[] | select(startswith("agent.") and (endswith(".sep") | not))')"

args=()
order=(front_app agents)
working=()
while IFS=$'\t' read -r item state name; do
	[[ -n "$item" ]] || continue
	if ! grep -qxF "$item" <<<"$shown"; then
		# A fixed icon width keeps the name still while the spinner's frames,
		# which differ in width, cycle.
		args+=(--add item "$item.sep" left --set "$item.sep" "${SEPARATOR[@]}"
			--add item "$item" left
			--set "$item" icon.font="PragmataPro Liga:Regular:13.0" icon.width=12
			icon.padding_right=4 label.color=0xff666666)
	fi
	glyph="" color=""
	read -r glyph color <<<"$(glyph_and_color "$state")"
	if [[ -n "$glyph" ]]; then
		args+=(--set "$item" icon.drawing=on icon="$glyph" icon.color="0xff$(palette_hex "$color")" label="$name")
	else
		args+=(--set "$item" icon.drawing=off label="$name")
	fi
	order+=("$item.sep" "$item")
	[[ "$state" == working ]] && working+=("$item")
done <<<"$agents"

for item in $shown; do
	cut -f1 <<<"$agents" | grep -qxF "$item" || args+=(--remove "$item" --remove "$item.sep")
done

sketchybar "${args[@]}" --reorder "${order[@]}"
printf '%s\n' "${working[@]}" >"$AGENTS_WORKING_FILE"
