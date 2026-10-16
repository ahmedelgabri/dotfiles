#!/usr/bin/env bash
# Exercises rx against a real Rex server on a private socket. Needs the Rex
# app, which is not in nixpkgs, so this is a live test outside nix checks.

# `rex do` is a subcommand, not a loop keyword.
# shellcheck disable=SC1010

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
RX_SRC="$ROOT/config/zsh.d/zsh/bin/rx"
REX_APP="/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"

if [[ ! -x "$REX_APP" ]]; then
	printf 'FAIL: Rex is not installed at %s\n' "$REX_APP" >&2
	exit 1
fi

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

# Runs a command, recording STATUS, OUT and ERR without tripping errexit.
run() {
	STATUS=0
	"$@" >"$WORK/out" 2>"$WORK/err" || STATUS=$?
	OUT=$(cat "$WORK/out")
	ERR=$(cat "$WORK/err")
}

assert_eq() {
	local what=$1 expected=$2 actual=$3
	[[ "$expected" == "$actual" ]] && return 0
	printf 'FAIL: %s\n' "$what" >&2
	diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") >&2 || true
	exit 1
}

expect() {
	local what=$1 status=$2 out=$3 err=$4
	shift 4
	run "$@"
	assert_eq "$what: status" "$status" "$STATUS"
	assert_eq "$what: stdout" "$out" "$OUT"
	assert_eq "$what: stderr" "$err" "$ERR"
}

# Pane shells load the full login zsh config, which takes a moment.
wait_for() {
	local what=$1 i
	shift
	for ((i = 0; i < ${WAIT_STEPS:-200}; i++)); do
		"$@" && return 0
		sleep 0.05
	done
	fail "timed out waiting for $what"
}

"$REX_APP" server run --listen "unix://$SOCKET" --state-dir "$WORK/state" \
	--config "$WORK/init.lua" >"$WORK/server.log" 2>&1 &
SERVER_PID=$!

# The rex CLI ignores REX_SERVER and silently falls back to the live server,
# so every call goes through a wrapper that pins -S.
mkdir -p "$WORK/bin"
printf '#!/bin/sh\nexec %q -S %q --autostart=false "$@"\n' \
	"$REX_APP" "unix://$SOCKET" >"$WORK/bin/rex"
chmod +x "$WORK/bin/rex"
for tool in bash sh basename cat sleep script stty grep sed head tail cut diff mkdir cp rm; do
	ln -s "$(command -v "$tool")" "$WORK/bin/$tool"
done
printf '#!%s\nexec %q %q "$@"\n' "$WORK/bin/bash" "$WORK/bin/bash" "$RX_SRC" >"$WORK/bin/rx"
chmod +x "$WORK/bin/rx"

# Only these tools are reachable, so shared.lua finds no aerc/newsraft/clx
# and the suite never launches them.
unset REX_SESSION REX_BLOCK REX_SERVER HOST_CONFIGS DEBUG
export PATH="$WORK/bin"
export XDG_CONFIG_HOME="$WORK/config"
export XDG_STATE_HOME="$WORK/xdg-state"
export DOTFILES="$WORK/dotfiles"
export NOTES_DIR="$WORK/notes"
export EDITOR=true
SESSIONS="$XDG_CONFIG_HOME/rex/sessions"
HOST_SESSIONS="$WORK/host/rex/sessions"
COMMANDS="$XDG_STATE_HOME/rx/commands"

mkdir -p "$SESSIONS" "$HOST_SESSIONS" "$XDG_CONFIG_HOME/rex/rx" "$COMMANDS" \
	"$DOTFILES" "$NOTES_DIR" "$WORK/proj" "$WORK/root/sub" "$WORK/other"
cp "$ROOT/config/rex/rx/shared.lua" "$XDG_CONFIG_HOME/rex/rx/"

server_up() {
	rex whoami >"$WORK/whoami" 2>&1
}
wait_for "private server" server_up
grep -qxF "endpoint: unix://$SOCKET" "$WORK/whoami" ||
	fail "not talking to the private server: $(cat "$WORK/whoami")"

# Prints a Lua expression's value as JSON, evaluated in session $1.
lua() {
	rex do -s "$1" -e "$2"
}

LABELS='local o = {}
for _, w in ipairs(rex.session.view({}).windows) do table.insert(o, w.label) end
return o'

# One line per window: label=<split tree with ratios and pane directories>
SHAPE='local t = "com.superlogical.terminal"
local function walk(n)
	if n.split then
		local s = n.split
		return s.direction .. "(" .. s.ratio .. "," .. walk(s.before) .. "," .. walk(s.after) .. ")"
	end
	return rex.block.call(t, "process", { block_id = n.block_id }).foreground.cwd
end
local o = {}
for _, w in ipairs(rex.session.view({}).windows) do
	table.insert(o, w.label .. "=" .. walk(w.layers[1].layout))
end
return table.concat(o, "\n")'

session_labels() {
	rex do -e 'local o = {}
for _, s in ipairs(rex.call("session.list").sessions) do table.insert(o, s.label) end
return o'
}

shape_ready() {
	lua "$1" "$SHAPE" >/dev/null 2>&1
}

# A new pane has no foreground process until its shell starts.
shape() {
	local json
	wait_for "panes of $1" shape_ready "$1"
	json=$(lua "$1" "$SHAPE")
	json=${json#\"}
	json=${json%\"}
	printf '%b\n' "$json"
}

screen_has() {
	rex capture -s "$1" -w "$2" --trim | grep -qF -- "$3"
}

foreground_is() {
	[[ $(lua "$1" "return rex.block.call('com.superlogical.terminal', 'process', { block_id = '$2' }).foreground.argv0") == "\"$3\"" ]]
}

# rx ends by attaching. Without a terminal rex refuses; everything before
# that is the behavior under test.
NO_TTY="Error: attach requires terminal output"

# --- usage -------------------------------------------------------------------

USAGE="Usage: rx [<name>] | rx --export [session]"
expect "help" 0 "$USAGE" "" rx --help
expect "too many args" 64 "" "$USAGE" rx a b
expect "unknown flag" 64 "" "$USAGE" rx --bogus
expect "export needs a session outside Rex" 64 "" \
	"rx: --export needs a session name outside Rex" rx --export
expect "export of a missing session" 3 "" \
	'Error: session target "nope" not found' rx --export nope

# --- plain session -----------------------------------------------------------

cd "$WORK/proj"
expect "plain session" 1 "" "$NO_TTY" rx
expect "plain session reused" 1 "" "$NO_TTY" rx
assert_eq "one session per label" '["proj"]' "$(session_labels)"
assert_eq "plain session windows" \
	"$(printf '%s\n' "dotfiles=horizontal(0.5,$DOTFILES,$DOTFILES)" "notes=$NOTES_DIR")" \
	"$(shape proj | tail -n +2)"
assert_eq "plain session root" "$WORK/proj" "$(shape proj | head -n 1 | cut -d= -f2)"

# --- definitions -------------------------------------------------------------

cat >"$SESSIONS/demo.lua" <<EOF
local shell = "com.superlogical.terminal.shell"
return {
	root = "$WORK/root",
	windows = {
		{
			label = "code",
			layout = rex.layout.vertical(0.3,
				rex.layout.block({ flavor = shell, options = { initial_input = "echo \\"it's\\" demo-marker\\n" } }),
				rex.layout.horizontal(0.6,
					rex.layout.block({ flavor = shell, options = { cwd = "sub" } }),
					rex.layout.block({ flavor = shell, options = { cwd = "$WORK/other" } }))),
		},
		{
			label = "long",
			layout = rex.layout.block({ flavor = shell, options = { initial_input = "sleep 300\\n" } }),
		},
	},
}
EOF

unset NOTES_DIR
expect "definition" 1 "" "$NO_TTY" rx demo
assert_eq "definition shape" "$(
	printf '%s\n' \
		"code=vertical(0.3,$WORK/root,horizontal(0.6,$WORK/root/sub,$WORK/other))" \
		"long=$WORK/root" \
		"dotfiles=horizontal(0.5,$DOTFILES,$DOTFILES)"
)" "$(shape demo)"
wait_for "definition command" screen_has demo 1 "it's demo-marker"
export NOTES_DIR="$WORK/notes"

for dir in "$SESSIONS:tracked" "$HOST_SESSIONS:from-host"; do
	printf 'return { windows = { { label = "%s", layout = rex.layout.block({ flavor = "com.superlogical.terminal.shell" }) } } }\n' \
		"${dir#*:}" >"${dir%:*}/dual.lua"
done
HOST_CONFIGS="$WORK/host" expect "host definition" 1 "" "$NO_TTY" rx dual
assert_eq "host definition wins" '["from-host","dotfiles","notes"]' "$(lua dual "$LABELS")"

printf 'error("boom", 0)\n' >"$SESSIONS/bad.lua"
expect "failing definition" 1 "" "Error: boom" rx bad
printf 'return 42\n' >"$SESSIONS/scalar.lua"
expect "definition without a table" 1 "" "Error: $SESSIONS/scalar.lua: must return a table" rx scalar
assert_eq "failed definitions create nothing" '["proj","demo","dual"]' "$(session_labels)"

# --- attach ------------------------------------------------------------------

# script gives rx a terminal; stty gives it a size, which rex attach needs.
# rex attach first queries the terminal's colors, and with nobody answering
# each query takes ~4s to time out, hence the long stdin and wait.
sleep 30 | script -q /dev/null sh -c 'stty cols 100 rows 30; exec rx demo' \
	>"$WORK/attach.out" 2>&1 &
ATTACH_PID=$!
attached() {
	grep -qF "demo" "$WORK/attach.out"
}
WAIT_STEPS=500 wait_for "attached client" attached
kill "$ATTACH_PID" 2>/dev/null || true
wait "$ATTACH_PID" 2>/dev/null || true

# --- export ------------------------------------------------------------------

code_block=$(lua demo 'return rex.session.view({}).windows[1].layers[1].layout.split.before.block_id')
code_block=${code_block//\"/}
long_block=$(lua demo 'return rex.session.view({}).windows[2].layers[1].layout.block_id')
long_block=${long_block//\"/}
wait_for "sleep in the long window" foreground_is demo "$long_block" sleep

printf '%s\n' "echo \"it's\" replayed-marker" >"$COMMANDS/$code_block"
printf '%s\n' "rx --export" >"$COMMANDS/$long_block"

EXPORTED=$(
	cat <<EOF
-- Generated by rx --export from session "demo".
-- Windows from rx/shared.lua are omitted; rx appends them to new sessions.
-- Recorded commands are replayed. Review them for secrets before saving this file.
-- Programs without a recorded command remain comments with their process names.

return {
	root = "$WORK/root",
	windows = {
		{
			label = "code",
			layout = rex.layout.vertical(
				0.3,
				rex.layout.block {
					flavor = "com.superlogical.terminal.shell",
					options = { initial_input = "echo \\"it's\\" replayed-marker\\n" },
				},
				rex.layout.horizontal(
					0.6,
					rex.layout.block {
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = "sub" },
					},
					rex.layout.block {
						flavor = "com.superlogical.terminal.shell",
						options = { cwd = "$WORK/other" },
					}
				)
			),
		},
		{
			label = "long",
			layout = rex.layout.block {
				-- running sleep (command not recorded)
				flavor = "com.superlogical.terminal.shell",
			},
		},
	},
}
EOF
)
# REX_BLOCK marks the long block as the one running the export, so its
# recorded command must not be replayed.
REX_BLOCK="$long_block" expect "export" 0 "$EXPORTED" "" rx --export demo

printf '%s\n' "$EXPORTED" >"$SESSIONS/copy.lua"
expect "exported definition" 1 "" "$NO_TTY" rx copy
assert_eq "round trip shape" \
	"$(shape demo | sed '/^notes=/d')" "$(shape copy | sed '/^notes=/d')"
wait_for "replayed command" screen_has copy 1 "it's replayed-marker"

echo "rx: all tests passed"
