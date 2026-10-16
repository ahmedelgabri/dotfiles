#!/usr/bin/env bash
# Exercises config/rex/init.lua, and the nvim half of pane navigation in
# config/nvim/plugin/core.lua, against a real Rex server on a private socket.
# Needs the Rex app, which is not in nixpkgs, so this is a live test outside
# nix checks.

# `rex do` is a subcommand, not a loop keyword.
# shellcheck disable=SC1010

set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
REX_APP="/Applications/Rex Beta.app/Contents/Helpers/Rex Server.rex/Contents/MacOS/rex"

if [[ ! -x "$REX_APP" ]]; then
	printf 'FAIL: Rex is not installed at %s\n' "$REX_APP" >&2
	exit 1
fi
for tool in nvim jq; do
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
	--config "$ROOT/config/rex/init.lua" >"$WORK/server.log" 2>&1 &
SERVER_PID=$!

# The rex CLI ignores REX_SERVER and silently falls back to the live server,
# so every call, including the ones nvim makes, goes through a wrapper that
# pins -S.
mkdir -p "$WORK/bin"
printf '#!/bin/sh\nexec %q -S %q --autostart=false "$@"\n' \
	"$REX_APP" "unix://$SOCKET" >"$WORK/bin/rex"
chmod +x "$WORK/bin/rex"
unset REX_SESSION REX_BLOCK REX_SERVER
export PATH="$WORK/bin:$PATH"

server_up() {
	rex whoami >"$WORK/whoami" 2>&1
}
wait_for "private server" server_up
grep -qxF "endpoint: unix://$SOCKET" "$WORK/whoami" ||
	fail "not talking to the private server: $(cat "$WORK/whoami")"

view() {
	rex api call -s "$1" session.view
}

# Window IDs in tab order.
windows() {
	view "$1" | jq -r '.windows[].window_id'
}

active_window() {
	view "$1" | jq -r '.active_window_id'
}

focused_block() {
	view "$1" | jq -r '.active_window_id as $a
		| .windows[] | select(.window_id == $a) | .focused_block_id'
}

zoomed_block() {
	view "$1" | jq -r '.active_window_id as $a
		| .windows[] | select(.window_id == $a) | .zoomed_block_id // "none"'
}

window_block() {
	view "$1" | jq -r --arg w "$2" \
		'.windows[] | select(.window_id == $w) | .focused_block_id'
}

# Prints a field of the block's foreground process, or nothing.
foreground() {
	rex api call -s "$1" block.method \
		"$(jq -nc --arg b "$2" '{block_id: $b, method: "process"}')" |
		jq -r --arg f "$3" '.foreground[$f] // empty'
}

cwd_is() {
	[[ "$(foreground "$1" "$2" cwd)" == "$3" ]]
}

type_into() {
	rex api call -s "$1" block.method "$(jq -nc --arg b "$2" --arg d "$3" \
		'{block_id: $b, method: "write", args: {data: $d}}')" >/dev/null
}

# Presses ctrl+KEY the way Rex.app does, through the config's bindings, and
# prints whether a binding consumed it.
press() {
	local cp
	cp=$(printf '%d' "'$2")
	rex api call -s "$1" client.key "$(jq -nc --arg k "key_$2" --argjson c "$cp" \
		'{key: {key: $k, mods: "ctrl", consumed_mods: "", text: "",
			unshifted_codepoint: $c, composing: false, action: "press"}}')" |
		jq -r '.handled'
}

# --- tab_new_next opens the tab in the current tab's directory -------------

mkdir -p "$WORK/work dir" "$WORK/other"
rex new tabs --cwd "$WORK/work dir" >/dev/null
first=$(active_window tabs)
first_block=$(window_block tabs "$first")
wait_for "first tab's shell" cwd_is tabs "$first_block" "$WORK/work dir"

# The action ends by asking the app to select the tab; without an app that
# step fails after the tab exists.
STATUS=0
rex do -s tabs tab_new_next >"$WORK/out" 2>"$WORK/err" || STATUS=$?
assert_eq "tab_new_next without an app: status" 1 "$STATUS"
assert_eq "tab_new_next without an app: stderr" \
	"Error: tab_new_next ran, but its client action was not delivered: no client is targeted. Use -C." \
	"$(cat "$WORK/err")"

second=$(active_window tabs)
assert_eq "last tab: order" "$first
$second" "$(windows tabs)"
wait_for "new tab in work dir" cwd_is tabs "$(window_block tabs "$second")" \
	"$WORK/work dir"

# From the first tab, after a cd, the new tab goes between the two.
rex api call -s tabs session.focus_window \
	"$(jq -nc --arg w "$first" '{window_id: $w}')" >/dev/null
type_into tabs "$first_block" "cd '$WORK/other'"$'\n'
wait_for "first tab's cd" cwd_is tabs "$first_block" "$WORK/other"
rex do -s tabs tab_new_next >/dev/null 2>&1 || true
third=$(active_window tabs)
assert_eq "middle tab: order" "$first
$third
$second" "$(windows tabs)"
wait_for "new tab in other" cwd_is tabs "$(window_block tabs "$third")" \
	"$WORK/other"

# --- ctrl+h/j/k/l move between Rex panes and nvim windows -------------------

# Pane commands start from the login shell's environment, not this one, so
# PATH (for the rex wrapper) and the nvim config must be passed in.
mkdir -p "$WORK/xdg"
ln -s "$ROOT/config/nvim" "$WORK/xdg/nvim"
printf 'a\n' >"$WORK/a.txt"
printf 'b\n' >"$WORK/b.txt"
NVIM_SOCKET="$WORK/nvim.sock"

rex new nav --cwd "$WORK" >/dev/null
shell=$(focused_block nav)
editor=$(rex split -s nav --json -- /usr/bin/env PATH="$PATH" \
	XDG_CONFIG_HOME="$WORK/xdg" nvim --listen "$NVIM_SOCKET" \
	-O "$WORK/a.txt" "$WORK/b.txt" | jq -r '.block_ids[0]')
below=$(rex split -s nav -b "$shell" --split=below --focus=false --json |
	jq -r '.block_ids[0]')

# nvim answers RPC while startup is still waiting on vim.pack, before
# plugin/core.lua has mapped anything, so wait for VimEnter.
nvim_up() {
	[[ "$(foreground nav "$editor" name)" == nvim ]] &&
		[[ "$(nvim --server "$NVIM_SOCKET" --remote-expr v:vim_did_enter 2>/dev/null)" == 1 ]]
}
wait_for "nvim" nvim_up
assert_eq "nvim maps ctrl+h from the checkout" \
	"$(cd "$ROOT/config/nvim/plugin" && pwd -P)/core.lua" \
	"$(nvim --server "$NVIM_SOCKET" --remote-expr 'luaeval("vim.uv.fs_realpath(
		debug.getinfo(vim.fn.maparg([[<C-h>]], [[n]], false, true).callback, [[S]])
		.source:sub(2))")')"

nvim_window() {
	nvim --server "$NVIM_SOCKET" --remote-expr 'winnr()'
}

name_of() {
	case "$1" in
	"$shell") printf 'shell' ;;
	"$editor") printf 'nvim' ;;
	"$below") printf 'below' ;;
	*) printf '%s' "$1" ;;
	esac
}

state() {
	local zoomed
	zoomed=$(zoomed_block nav)
	[[ "$zoomed" == none ]] || zoomed=$(name_of "$zoomed")
	printf 'focus=%s nvim=%s zoom=%s' "$(name_of "$(focused_block nav)")" \
		"$(nvim_window)" "$zoomed"
}

state_is() {
	[[ "$(state)" == "$1" ]]
}

# nvim hands an edge move to Rex in the background, so a step that must not
# move focus waits long enough for a wrong move to land before it checks.
step() {
	local what=$1 key=$2 handled=$3 expected=$4
	assert_eq "$what: handled" "$handled" "$(press nav "$key")"
	sleep 0.5
	WAIT_STEPS=40 wait_for "$what: $expected (now $(state))" state_is "$expected"
}

rex focus -s nav "$shell" >/dev/null
wait_for "start in the shell" state_is "focus=shell nvim=1 zoom=none"

step "shell ctrl+l goes to nvim" l true "focus=nvim nvim=1 zoom=none"
step "nvim ctrl+l goes to its right window" l false "focus=nvim nvim=2 zoom=none"
# Rex picks the pane on the far side by position, not by recent use, so from
# the full-height nvim pane it lands on the top one.
step "nvim ctrl+l at its right edge wraps to Rex's left side" l false \
	"focus=shell nvim=2 zoom=none"
step "shell ctrl+h at the left edge wraps to nvim" h true \
	"focus=nvim nvim=2 zoom=none"
step "nvim ctrl+h goes to its left window" h false "focus=nvim nvim=1 zoom=none"
step "nvim ctrl+h at its left edge goes to Rex" h false \
	"focus=shell nvim=1 zoom=none"
step "shell ctrl+j goes below" j true "focus=below nvim=1 zoom=none"
step "below ctrl+j at the bottom edge wraps to the top" j true \
	"focus=shell nvim=1 zoom=none"
step "shell ctrl+k at the top edge wraps to the bottom" k true \
	"focus=below nvim=1 zoom=none"
step "below ctrl+k comes back" k true "focus=shell nvim=1 zoom=none"

rex focus -s nav "$editor" >/dev/null
rex zoom -s nav -b "$editor" --on >/dev/null
wait_for "nvim zoomed" state_is "focus=nvim nvim=1 zoom=nvim"
step "zoomed nvim ctrl+h at its edge stays zoomed" h false \
	"focus=nvim nvim=1 zoom=nvim"
step "zoomed nvim ctrl+l still moves inside nvim" l false \
	"focus=nvim nvim=2 zoom=nvim"
step "zoomed nvim ctrl+l at its edge does not wrap" l false \
	"focus=nvim nvim=2 zoom=nvim"

# A zoomed shell behaves like tmux's select-pane: it unzooms and moves.
rex zoom -s nav -b "$editor" --off >/dev/null
rex focus -s nav "$shell" >/dev/null
rex zoom -s nav -b "$shell" --on >/dev/null
wait_for "shell zoomed" state_is "focus=shell nvim=2 zoom=shell"
step "zoomed shell ctrl+l unzooms and goes to nvim" l true \
	"focus=nvim nvim=2 zoom=none"

nvim --server "$NVIM_SOCKET" --remote-send '<Esc>:qa!<CR>' >/dev/null 2>&1 || true

printf 'rex init.lua: ok\n'
