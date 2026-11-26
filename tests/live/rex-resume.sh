#!/usr/bin/env bash
# Starts actual pi with the rex-resume extension in a real Rex server on a
# private socket, restarts that server, and checks that Rex resumes the same
# pi session. Needs the Rex app, which is not in nixpkgs, so this is a live
# test outside nix checks.

# `rex do` is a subcommand, not a loop keyword.
# shellcheck disable=SC1010

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
REX_APP="/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"
EXTENSION="$ROOT/config/pi/agent/extensions/rex-resume/index.ts"

if [[ ! -x "$REX_APP" ]]; then
	printf 'FAIL: Rex is not installed at %s\n' "$REX_APP" >&2
	exit 1
fi
for tool in pi jq zsh; do
	command -v "$tool" >/dev/null || {
		printf 'FAIL: %s is not on PATH\n' "$tool" >&2
		exit 1
	}
done

# Unix socket paths are limited to ~104 bytes, so the socket cannot live in a
# deep scratch directory. Rex reports resolved paths (/private/var on macOS).
WORK=$(mktemp -d)
WORK=$(cd "$WORK" && pwd -P)
SOCKET="$WORK/r.sock"
SERVER_PID=""

cleanup() {
	if [[ -n "$SERVER_PID" ]]; then
		kill "$SERVER_PID" 2>/dev/null || true
		wait "$SERVER_PID" 2>/dev/null || true
	fi
	rm -rf "$WORK"
}
trap cleanup EXIT

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

assert_eq() {
	local what=$1 expected=$2 actual=$3
	[[ "$expected" == "$actual" ]] && return 0
	printf 'FAIL: %s\n' "$what" >&2
	diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") >&2 || true
	exit 1
}

wait_for() {
	local what=$1 i
	shift
	for ((i = 0; i < ${WAIT_STEPS:-300}; i++)); do
		"$@" && return 0
		sleep 0.05
	done
	fail "timed out waiting for $what"
}

# Pane shells run bare zsh with this checkout's resume-report on PATH, and pi
# keeps its state in the work directory. The pane's token comes from the
# private server, never from the terminal running this suite.
mkdir -p "$WORK/zdot" "$WORK/proj" "$WORK/pi"
printf 'setopt no_global_rcs\n' >"$WORK/zdot/.zshenv"
cat >"$WORK/zdot/.zshrc" <<EOF
PS1='%% '
export PATH=${ROOT@Q}/config/zsh.d/zsh/bin:${PATH@Q}
export PI_CODING_AGENT_DIR=${WORK@Q}/pi PI_OFFLINE=1 PI_SKIP_VERSION_CHECK=1
EOF
unset REX_SESSION REX_BLOCK REX_SERVER OSC7577_TOKEN TMUX TMUX_PANE

start_server() {
	ZDOTDIR="$WORK/zdot" "$REX_APP" server run --listen "unix://$SOCKET" \
		--state-dir "$WORK/state" --config "$ROOT/config/rex/init.lua" \
		>>"$WORK/server.log" 2>&1 &
	SERVER_PID=$!
	wait_for "private server" server_up
}
stop_server() {
	zrex server stop >/dev/null
	wait "$SERVER_PID" 2>/dev/null || true
	SERVER_PID=""
}
server_up() {
	zrex whoami >"$WORK/whoami" 2>&1
}
# The rex CLI uses the live server unless told otherwise, so every call pins
# -S.
zrex() {
	"$REX_APP" -S "unix://$SOCKET" --autostart=false "$@"
}
records() {
	zrex block call -b "$block" program_resume_records
}
reported() {
	[[ $(records | jq '.records | length') -gt 0 ]]
}
foreground_pid() {
	zrex block call -b "$block" process | jq -r '.foreground.pid // empty'
}
runs_pi() {
	[[ $(zrex block call -b "$block" process | jq -r .foreground.name) == pi ]]
}

start_server
grep -qxF "endpoint: unix://$SOCKET" "$WORK/whoami" ||
	fail "rex does not use the private server: $(cat "$WORK/whoami")"

zrex new -c "$WORK/proj" resume >/dev/null
block=$(zrex do -s resume -e 'return rex.session.view({}).windows[1].layers[1].layout.block_id')
block=${block//\"/}
zrex send -b "$block" "pi --no-extensions --no-context-files --no-skills --extension ${EXTENSION@Q}"$'\n'
wait_for "a resume report" reported

record=$(records | jq -c '.records[0]')
assert_eq "record is trusted by the pi rule" '"pi" true true' \
	"$(jq -r '"\"\(.rule)\" \(.trusted) \(.chosen)"' <<<"$record")"
assert_eq "record directory" "$WORK/proj" "$(jq -r .cwd <<<"$record")"
id=$(jq -r '.command[2]' <<<"$record")
assert_eq "record command" "pi --session-id $id" "$(jq -r '.command | join(" ")' <<<"$record")"
[[ $id =~ ^[0-9a-f]{8}-([0-9a-f]{4}-){3}[0-9a-f]{12}$ ]] || fail "session id is not a UUID: $id"

stop_server
start_server
wait_for "pi resumed in the restored block" runs_pi
assert_eq "resumed command" "pi --session-id $id" \
	"$(ps -o args= -p "$(foreground_pid)" | sed 's/^[^ ]*\/pi /pi /')"
stop_server

echo "rex-resume: all tests passed"
