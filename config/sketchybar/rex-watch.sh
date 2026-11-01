#!/usr/bin/env bash
# Rex pushes program status changes, so the agent items update as soon as an
# agent changes state instead of waiting for their poll.

# shellcheck source=SCRIPTDIR/segments.sh
source "$(dirname "$0")/segments.sh"

single_instance rex-watch || exit 0

# `rex events` ends when the Rex server goes away, so retry while SketchyBar
# is still running. A failed trigger means SketchyBar quit.
while sketchybar --query bar >/dev/null 2>&1; do
	rex events --all --json 2>/dev/null |
		jq --unbuffered -r 'select(.payload.event.payload.name? // "" | startswith("program_status")) | "changed"' |
		while read -r _; do
			sketchybar --trigger rex_agents_changed || break
		done
	sleep 5
done
