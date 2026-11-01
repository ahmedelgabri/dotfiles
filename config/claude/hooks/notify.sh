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

# Rex surfaces Claude notifications itself, so a second one here would
# duplicate them.
if [ -n "${REX_SESSION:-}" ]; then
	exit 0
fi

if command -v terminal-notifier >/dev/null 2>&1; then
	printf '%s' "$message" | terminal-notifier -title Claude -subtitle "Notification hook"
elif command -v notify-send >/dev/null 2>&1; then
	notify-send Claude "$message"
fi

exit 0
