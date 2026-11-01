#!/usr/bin/env bash
# SketchyBar passes the app name in $INFO only on front_app_switched, so the
# first update after a (re)load asks macOS instead.

if [[ "${SENDER-}" == front_app_switched ]]; then
	app="$INFO"
else
	app="$(lsappinfo info "$(lsappinfo front)" | sed -n '1s/^"\([^"]*\)".*/\1/p')"
fi

sketchybar --set "$NAME" label="$app"
