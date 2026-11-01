#!/usr/bin/env bash
# Animates the icons of working agents, which agents.sh lists in
# $AGENTS_WORKING_FILE. SketchyBar's update_freq can't go below a second, so a
# spinner needs its own loop.

# shellcheck source=SCRIPTDIR/segments.sh
source "$(dirname "$0")/segments.sh"

single_instance spinner || exit 0

frame=0
while true; do
	args=()
	if [[ -s "$AGENTS_WORKING_FILE" ]]; then
		while read -r item; do
			[[ -n "$item" ]] && args+=(--set "$item" icon="${SPINNER_FRAMES[frame]}")
		done <"$AGENTS_WORKING_FILE"
	fi

	if ((${#args[@]} == 0)); then
		sketchybar --query bar >/dev/null 2>&1 || exit 0
		sleep 1
		continue
	fi

	# A failed --set can also mean agents.sh just removed an item, so only stop
	# once SketchyBar itself is gone.
	sketchybar "${args[@]}" >/dev/null 2>&1 ||
		sketchybar --query bar >/dev/null 2>&1 || exit 0
	frame=$(((frame + 1) % ${#SPINNER_FRAMES[@]}))
	sleep 0.1
done
