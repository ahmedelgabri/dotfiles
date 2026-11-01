#!/usr/bin/env bash
# SketchyBar sets $NAME to the item that triggered this script.

# shellcheck source=SCRIPTDIR/segments.sh
source "$(dirname "$0")/segments.sh"

IFS=$'\t' read -r color text < <(run_segment "$NAME")

draw=on
[[ -n "$text" ]] || draw=off

args=(--set "$NAME" drawing="$draw")
if [[ "$draw" == on ]]; then
	args+=(label="$text" label.color="0xff$(palette_hex "$color")")
fi

# $1 is this segment's separator item, if it has one.
if [[ -n "${1-}" ]]; then
	args+=(--set "$1" drawing="$draw")
fi

sketchybar "${args[@]}"
