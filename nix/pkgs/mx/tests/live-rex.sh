#!/usr/bin/env bash
# Exercises the built mx package's Rex backend against a real Rex server on a
# private socket: MX_BIN=<package>/bin bash nix/pkgs/mx/tests/live-rex.sh
# It needs the Rex app, which is not in nixpkgs, so this is a live test
# outside nix checks.

# `rex do` is a subcommand, not a loop keyword.
# shellcheck disable=SC1010

set -euo pipefail

: "${MX_BIN:?set MX_BIN to the bin directory of the mx package}"
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
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

# The rex CLI uses the live server unless told otherwise, so every call goes
# through a wrapper that pins -S.
mkdir -p "$WORK/bin"
printf '#!/bin/sh\nexec %q -S %q --autostart=false "$@"\n' \
	"$REX_APP" "unix://$SOCKET" >"$WORK/bin/rex"
chmod +x "$WORK/bin/rex"
for tool in bash sh basename dirname cat sleep script stty grep sed head tail cut tr diff mkdir mktemp cp mv rm awk wc; do
	ln -s "$(command -v "$tool")" "$WORK/bin/$tool"
done
ln -s "$MX_BIN/mx" "$WORK/bin/mx"

# Only these tools are reachable, so shared.lua finds no aerc/newsraft/clx
# and the suite never launches them. Outside a Rex terminal mx would pick
# tmux, so the backend is forced.
unset REX_SESSION REX_BLOCK REX_SERVER TMUX TMUX_PANE HOST_CONFIGS DEBUG
export MX_BACKEND=rex
export PATH="$WORK/bin"
export XDG_CONFIG_HOME="$WORK/config"
export XDG_STATE_HOME="$WORK/xdg-state"
export DOTFILES="$WORK/dotfiles"
export NOTES_DIR="$WORK/notes"
export PROJECTS="$WORK/projects"
export EDITOR=true
SESSIONS="$XDG_CONFIG_HOME/mx/sessions"
HOST_SESSIONS="$WORK/host/mx/sessions"
COMMANDS="$XDG_STATE_HOME/mx/commands"

mkdir -p "$SESSIONS" "$HOST_SESSIONS" "$COMMANDS" "$PROJECTS" \
	"$DOTFILES" "$NOTES_DIR" "$WORK/proj" "$WORK/root/sub" "$WORK/other"
cp "$ROOT/config/mx/shared.lua" "$XDG_CONFIG_HOME/mx/"

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

# One line per window: label=<split tree with ratios and pane directories>,
# with a * after the window's focused pane. An unlabeled window's name is
# Rex's own, so checks blank the first window's label.
SHAPE='local t = "com.superlogical.terminal"
local function walk(n, focused)
	if n.split then
		local s = n.split
		return s.direction .. "(" .. s.ratio .. "," .. walk(s.before, focused) .. "," .. walk(s.after, focused) .. ")"
	end
	local cwd = rex.block.call(t, "process", { block_id = n.block_id }).foreground.cwd
	return cwd .. (n.block_id == focused and "*" or "")
end
local o = {}
for _, w in ipairs(rex.session.view({}).windows) do
	table.insert(o, (w.label or "") .. "=" .. walk(w.layers[1].layout, w.focused_block_id))
end
return table.concat(o, "\n")'

session_labels() {
	rex do -e 'local o = {}
for _, s in ipairs(rex.call("session.list").sessions) do table.insert(o, s.label) end
return o'
}

shape_ready() {
	lua "$1" "$SHAPE" >"$WORK/shape" 2>/dev/null
}

# A pane has no foreground process until its shell starts, nor for a moment
# while it starts a program, so the shape comes from a query that worked.
shape() {
	local json
	wait_for "panes of $1" shape_ready "$1"
	json=$(cat "$WORK/shape")
	json=${json#\"}
	json=${json%\"}
	printf '%b\n' "$json"
}

# The first pane of window $2 in session $1, which may not be the focused one.
first_block() {
	local id
	id=$(lua "$1" "local n = rex.session.view({}).windows[$2].layers[1].layout
while n.split do n = n.split.before end
return n.block_id")
	printf '%s\n' "${id//\"/}"
}

screen_has() {
	rex capture -s "$1" -b "$(first_block "$1" "$2")" --trim | grep -qF -- "$3"
}

foreground_is() {
	[[ $(lua "$1" "return rex.block.call('com.superlogical.terminal', 'process', { block_id = '$2' }).foreground.argv0") == "\"$3\"" ]]
}

# Outside Rex, mx ends by attaching. Without a terminal rex refuses;
# everything before that is the behavior under test.
NO_TTY="Error: attach requires terminal output"
SHARED="dotfiles=horizontal(0.5,$DOTFILES*,$DOTFILES)
notes=$NOTES_DIR*"

# --- usage -------------------------------------------------------------------

expect "export needs a session outside Rex" 64 "" \
	"mx: --export needs a session name outside Rex" mx --export
expect "export of a missing session" 3 "" \
	'mx: session target "nope" not found' mx --export nope

# --- plain session -----------------------------------------------------------

cd "$WORK/proj"
expect "plain session" 1 "" "$NO_TTY" mx
expect "plain session reused" 1 "" "$NO_TTY" mx
assert_eq "one session per label" '["proj"]' "$(session_labels)"
assert_eq "plain session windows" "=$WORK/proj*
$SHARED" "$(shape proj | sed '1s/^[^=]*=/=/')"

# --- definitions -------------------------------------------------------------

cat >"$SESSIONS/demo.lua" <<EOF
return {
	root = "$WORK/root",
	windows = {
		{
			label = "code",
			layout = {
				split = "vertical",
				ratio = 0.3,
				{ command = [[echo "it's" demo-marker]] },
				{
					split = "horizontal",
					ratio = 0.6,
					{ cwd = "sub" },
					{ cwd = "$WORK/other", focus = true },
				},
			},
		},
		{ label = "long", layout = { command = "sleep 300" } },
	},
}
EOF

unset NOTES_DIR
expect "definition" 1 "" "$NO_TTY" mx demo
assert_eq "definition shape" "code=vertical(0.3,$WORK/root,horizontal(0.6,$WORK/root/sub,$WORK/other*))
long=$WORK/root*
dotfiles=horizontal(0.5,$DOTFILES*,$DOTFILES)" "$(shape demo)"
assert_eq "first window active" '"code"' \
	"$(lua demo 'local v = rex.session.view({}) for _, w in ipairs(v.windows) do if w.window_id == v.active_window_id then return w.label end end')"
wait_for "definition command" screen_has demo 1 "it's demo-marker"
export NOTES_DIR="$WORK/notes"

for dir in "$SESSIONS:tracked" "$HOST_SESSIONS:from-host"; do
	printf "return { windows = { { label = '%s' } } }\n" "${dir#*:}" >"${dir%:*}/dual.lua"
done
HOST_CONFIGS="$WORK/host" expect "host definition" 1 "" "$NO_TTY" mx dual
assert_eq "host definition wins" '["from-host","dotfiles","notes"]' "$(lua dual "$LABELS")"

printf 'error("boom", 0)\n' >"$SESSIONS/bad.lua"
expect "failing definition" 1 "" "mx: $SESSIONS/bad.lua: boom" mx bad
printf 'return 42\n' >"$SESSIONS/scalar.lua"
expect "definition without a table" 1 "" "mx: $SESSIONS/scalar.lua: must return a table" mx scalar
assert_eq "failed definitions create nothing" '["proj","demo","dual"]' "$(session_labels)"

# --- refill ------------------------------------------------------------------

# Rex keeps a session whose last window closed; mx gives it its windows back.
rex do -e 'return rex.call("session.create", { label = "emptied" }).session_id' >/dev/null
assert_eq "emptied starts with no windows" '0' "$(lua emptied 'return #(rex.session.view({}).windows or {})')"
cd "$WORK/proj"
expect "refill" 1 "" "$NO_TTY" mx emptied
assert_eq "refilled windows" "=$WORK/proj*
$SHARED" "$(shape emptied | sed '1s/^[^=]*=/=/')"

# --- attach ------------------------------------------------------------------

# script gives mx a terminal; stty gives it a size, which rex attach needs.
# rex attach first queries the terminal's colors, and with nobody answering
# each query takes ~4s to time out, hence the long stdin and wait.
sleep 30 | script -q /dev/null sh -c 'stty cols 100 rows 30; exec mx demo' \
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
printf '%s\n' "mx --export" >"$COMMANDS/$long_block"

EXPORTED=$(
	cat <<EOF
-- Generated by mx --export from session 'demo'.
-- Windows from shared.lua are omitted; mx adds them to new sessions.
-- Recorded commands are replayed. Review them for secrets before saving.
-- Programs without a recorded command stay as comments.

return {
	root = '$WORK/root',
	windows = {
		{
			label = 'code',
			layout = {
				split = 'vertical',
				ratio = 0.3,
				{
					command = 'echo "it\\'s" replayed-marker',
				},
				{
					split = 'horizontal',
					ratio = 0.6,
					{
						cwd = 'sub',
					},
					{
						cwd = '$WORK/other',
						focus = true,
					},
				},
			},
		},
		{
			label = 'long',
			layout = {
				-- running sleep (command not recorded)
			},
		},
	},
}
EOF
)
# REX_BLOCK marks the long block as the one running the export, so its
# recorded command must not be replayed.
REX_BLOCK="$long_block" expect "export" 0 "$EXPORTED" "" mx --export demo

printf '%s\n' "$EXPORTED" >"$SESSIONS/copy.lua"
expect "exported definition" 1 "" "$NO_TTY" mx copy
assert_eq "round trip shape" \
	"$(shape demo | sed '/^notes=/d')" "$(shape copy | sed '/^notes=/d')"
wait_for "replayed command" screen_has copy 1 "it's replayed-marker"

# --- migrating rx definitions ------------------------------------------------

mkdir -p "$XDG_CONFIG_HOME/rex/sessions"
cat >"$XDG_CONFIG_HOME/rex/sessions/legacy.lua" <<EOF
local shell = "com.superlogical.terminal.shell"
return {
	root = "$WORK/root",
	windows = {
		{
			label = "code",
			layout = rex.layout.vertical(0.3,
				rex.layout.block({ flavor = shell, options = { initial_input = "echo legacy-marker\\n" } }),
				rex.layout.horizontal(0.6,
					rex.layout.block({ flavor = shell, options = { cwd = "sub" } }),
					rex.layout.block({ flavor = shell, options = { cwd = "$WORK/other" } }))),
		},
	},
}
EOF
printf 'return { windows = {} }\n' >"$XDG_CONFIG_HOME/rex/sessions/demo.lua"

expect "--migrate" 0 "$XDG_CONFIG_HOME/rex/sessions/legacy.lua -> $SESSIONS/legacy.lua" \
	"mx: skipped $XDG_CONFIG_HOME/rex/sessions/demo.lua: $SESSIONS/demo.lua exists" mx --migrate
assert_eq "migrated rx definition" "-- Converted by mx --migrate from '$XDG_CONFIG_HOME/rex/sessions/legacy.lua'.
-- Windows from shared.lua are omitted; mx adds them to new sessions.
-- Recorded commands are replayed. Review them for secrets before saving.
-- Programs without a recorded command stay as comments.

return {
	root = '$WORK/root',
	windows = {
		{
			label = 'code',
			layout = {
				split = 'vertical',
				ratio = 0.3,
				{
					command = 'echo legacy-marker',
				},
				{
					split = 'horizontal',
					ratio = 0.6,
					{
						cwd = 'sub',
					},
					{
						cwd = '$WORK/other',
					},
				},
			},
		},
	},
}" "$(cat "$SESSIONS/legacy.lua")"
expect "migrated definition opens" 1 "" "$NO_TTY" mx legacy
wait_for "migrated command" screen_has legacy 1 "legacy-marker"

echo "mx (Rex): all tests passed"
