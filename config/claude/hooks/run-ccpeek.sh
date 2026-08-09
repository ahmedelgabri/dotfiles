#!/usr/bin/env bash
set -ue -o pipefail

# Stop-hook wrapper for ccpeek. settings.json is shared between the darwin
# and nixos hosts, so the platform log location (and whether ccpeek exists
# at all) is resolved here at runtime instead of baking the darwin-only
# ~/Library/Logs path into the hook command line.
if ! command -v ccpeek >/dev/null 2>&1; then
	exit 0
fi

if [ "$(uname -s)" = "Darwin" ]; then
	LOG_DIR="$HOME/Library/Logs"
else
	LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
fi
mkdir -p "$LOG_DIR"

exec ccpeek --index-only --skip-scan --quiet \
	>>"$LOG_DIR/ccpeek-stdout.log" 2>>"$LOG_DIR/ccpeek-stderr.log"
