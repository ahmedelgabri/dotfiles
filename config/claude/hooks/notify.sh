#!/usr/bin/env bash
set -ue -o pipefail

# Notification-hook dispatcher. settings.json is shared between the darwin
# and nixos hosts, so the platform-appropriate notifier is resolved here at
# runtime instead of hardcoding the darwin-only terminal-notifier in the
# hook command line.

message=$(jq -r '.message // empty')
message=$(printf '%s' "$message" | tr -d '\000-\037')
if [ -z "$message" ]; then
	exit 0
fi

# GHOSTTY_BIN_DIR is only set inside Ghostty, which surfaces Claude
# notifications itself. tmux consumes those escape sequences, so send an
# explicit passthrough sequence to the pane TTY when running inside tmux.
if [ -n "${GHOSTTY_BIN_DIR:-}" ]; then
	if [ -n "${TMUX:-}" ] && command -v tmux >/dev/null 2>&1; then
		pane_tty=$(tmux display-message -p -t "${TMUX_PANE:-}" '#{pane_tty}' 2>/dev/null || true)
		if [ -n "$pane_tty" ] && [ -w "$pane_tty" ]; then
			printf '\033Ptmux;\033\033]777;notify;Claude;%s\007\033\134' "$message" >"$pane_tty"
		fi
	fi
	exit 0
fi

if command -v terminal-notifier >/dev/null 2>&1; then
	printf '%s' "$message" | terminal-notifier -title Claude -subtitle "Notification hook" -activate com.mitchellh.ghostty
elif command -v notify-send >/dev/null 2>&1; then
	notify-send Claude "$message"
fi

exit 0
