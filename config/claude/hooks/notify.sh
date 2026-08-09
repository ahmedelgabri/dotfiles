#!/usr/bin/env bash
set -ue -o pipefail

# Notification-hook dispatcher. settings.json is shared between the darwin
# and nixos hosts, so the platform-appropriate notifier is resolved here at
# runtime instead of hardcoding the darwin-only terminal-notifier in the
# hook command line.

# GHOSTTY_BIN_DIR is only set inside Ghostty, which surfaces Claude
# notifications itself; only sessions in other terminals need an explicit
# desktop notification (the -activate flag focuses Ghostty on click).
if [ -n "${GHOSTTY_BIN_DIR:-}" ]; then
	exit 0
fi

message=$(jq -r '.message // empty')
if [ -z "$message" ]; then
	exit 0
fi

if command -v terminal-notifier >/dev/null 2>&1; then
	printf '%s' "$message" | terminal-notifier -title Claude -subtitle "Notification hook" -activate com.mitchellh.ghostty
elif command -v notify-send >/dev/null 2>&1; then
	notify-send Claude "$message"
fi

exit 0
