#!/usr/bin/env bash
# Exercises the built mx package against a real tmux server on a private
# socket: MX_BIN=<package>/bin bash nix/pkgs/mx/tests/mx.sh
set -euo pipefail

: "${MX_BIN:?set MX_BIN to the bin directory of the mx package}"
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)

WORK=$(mktemp -d)
# tmux reports resolved paths (/private/var on macOS), so compare against those
WORK=$(cd "$WORK" && pwd -P)
SOCKET="$WORK/tmux-$(id -u)/default"
# tmux only creates its socket dir when it picks the path itself, not when the
# path comes from $TMUX.
mkdir -m 700 "${SOCKET%/*}"

# Never touch the caller's tmux server, even when the suite runs inside tmux.
t() {
	tmux -S "$SOCKET" "$@"
}

cleanup() {
	t kill-server 2>/dev/null || true
	rm -rf "$WORK"
}
trap cleanup EXIT

# Only these tools are reachable, so shared.lua cannot find aerc/newsraft/clx
# on the host and launch them.
mkdir -p "$WORK/bin"
for tool in tmux bash awk sed wc basename dirname tail tr mktemp cat cp mv env sleep touch mkdir rm diff id chmod; do
	tool_path=$(command -v "$tool")
	ln -s "$tool_path" "$WORK/bin/$tool"
done
ln -s "$MX_BIN/mx" "$WORK/bin/mx"

unset TMUX TMUX_PANE REX_SESSION REX_BLOCK REX_SERVER MX_BACKEND HOST_CONFIGS DEBUG XDG_STATE_HOME
export LC_ALL=C
export PATH="$WORK/bin"
export SHELL="$WORK/bin/bash"
export HOME="$WORK/home"
export XDG_CONFIG_HOME="$HOME/.config"
export TMUX_TMPDIR="$WORK"
export PROJECTS="$HOME/Projects"
export NOTES_DIR="$WORK/notes"
export DOTFILES="$WORK/dotfiles"
export EDITOR=true
SESSIONS="$XDG_CONFIG_HOME/mx/sessions"
HOST_SESSIONS="$WORK/host/mx/sessions"
COMMANDS="$HOME/.local/state/mx/commands"

mkdir -p "$SESSIONS" "$HOST_SESSIONS" "$NOTES_DIR" "$DOTFILES" "$COMMANDS" "$XDG_CONFIG_HOME/tmux"
cp "$ROOT/config/mx/shared.lua" "$XDG_CONFIG_HOME/mx/shared.lua"
# Match the real config's indexing, which --export's `window=1` relies on,
# and skip login rc files that could put host tools back on PATH.
cat >"$XDG_CONFIG_HOME/tmux/tmux.conf" <<'EOF'
set -g base-index 1
setw -g pane-base-index 1
set -g default-command 'exec "$SHELL" --noprofile --norc'
EOF

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

# Stands in for the zsh preexec hook in extras.zsh.
record() {
	local pane
	pane=$(t display-message -p -t "$1" '#{pid}-#{pane_id}')
	printf '%s\n' "$2" >"$COMMANDS/tmux-${pane/\%/}"
}

# mx always ends by handing the terminal to tmux. With no client to switch,
# tmux reports it; everything before that is the behavior under test.
in_tmux() {
	TMUX="$SOCKET,0,0" "$@"
}

NO_CLIENT="no current client"

wait_for() {
	local what=$1 i
	shift
	for ((i = 0; i < 100; i++)); do
		"$@" && return 0
		sleep 0.05
	done
	fail "timed out waiting for $what"
}

# Panes started with 'exec sleep' briefly show the shell that execs it.
pane_execed() {
	local command
	command=$(t display-message -p -t "$1" '#{pane_current_command}')
	[[ "$command" != bash ]]
}

project() {
	mkdir -p "$PROJECTS/$1"
}

marker() {
	mkdir -p "$PROJECTS/$1"
	touch "$PROJECTS/$1/$2"
}

# --- fixture ---------------------------------------------------------------

marker work/acme/app/.git config
project work/acme/mono/.bare
marker work/acme/mono/main .git
marker work/acme/mono/feature .git
project work/acme/mono/_
touch "$PROJECTS/work/acme/notes.txt"
project trunk/tool/src
project trunk/v1.2
project personal/app
project personal/.hidden
project forks/lib
project ahmedelgabri/dots
project archive/old/.jj
project archive/old2/.bare
marker archive/old2/wt .git
project archive/old2/scratch
project archive/group/x
project archive/group/y

cat >"$SESSIONS/shared-name.lua" <<'EOF'
return { root = os.getenv 'PROJECTS' .. '/forks/lib' }
EOF
cat >"$HOST_SESSIONS/shared-name.lua" <<'EOF'
return { root = os.getenv 'PROJECTS' .. '/personal/app' }
EOF
printf 'return {}\n' >"$HOST_SESSIONS/beta.lua"
printf 'not a definition\n' >"$SESSIONS/README.md"
mkdir "$SESSIONS/not-a-definition.lua"
cat >"$SESSIONS/broken.lua" <<'EOF'
return { windows = { { layout = { split = 'diagonal', {}, {} } } } }
EOF

cat >"$SESSIONS/alpha.lua" <<'EOF'
return {
	root = os.getenv 'PROJECTS' .. '/trunk/tool',
	windows = {
		{
			label = 'editor',
			layout = {
				split = 'horizontal',
				ratio = 0.7,
				{},
				{ cwd = 'src', command = 'exec sleep 600', focus = true },
			},
		},
		{
			label = 'build logs',
			layout = {
				split = 'vertical',
				ratio = 1 / 3,
				{ cwd = os.getenv 'HOME', command = 'exec sleep 600' },
				{
					split = 'vertical',
					ratio = 0.5,
					{ cwd = os.getenv 'DOTFILES', command = 'exec sleep 600', focus = true },
					{ cwd = '..', command = 'exec sleep 600' },
				},
			},
		},
		{ label = 'last', layout = { command = 'exec sleep 600' } },
	},
}
EOF

# --- usage -----------------------------------------------------------------

USAGE="Usage: mx [<name>] | mx --dir <path> | mx --list | mx --pick [query] | mx --export [session] | mx --migrate"

expect "--help" 0 "$USAGE" "" mx --help
expect "-h" 0 "$USAGE" "" mx -h
expect "--help with extra argument" 64 "" "$USAGE" mx --help extra
expect "unknown option" 64 "" "$USAGE" mx --bogus
expect "--list with extra argument" 64 "" "$USAGE" mx --list extra
expect "--dir without path" 64 "" "$USAGE" mx --dir
expect "--dir to missing path" 64 "" "$USAGE" mx --dir "$WORK/missing"
expect "--pick with two queries" 64 "" "$USAGE" mx --pick a b
expect "--export with two sessions" 64 "" "$USAGE" mx --export a b
expect "two names" 64 "" "$USAGE" mx a b
expect "unknown backend" 64 "" "mx: MX_BACKEND must be tmux or rex, not screen" \
	env MX_BACKEND=screen mx --list

run env -u PROJECTS mx --list
assert_eq "--list without PROJECTS: status" 1 "$STATUS"
[[ "$OUT" == "" && "$ERR" == *"PROJECTS: PROJECTS is not set" ]] ||
	fail "--list without PROJECTS: got [$OUT] [$ERR]"

# --- listing ---------------------------------------------------------------

P=$PROJECTS
expect "--list" 0 "sess	beta	$HOST_SESSIONS/beta.lua
sess	shared-name	$HOST_SESSIONS/shared-name.lua
sess	alpha	$SESSIONS/alpha.lua
sess	broken	$SESSIONS/broken.lua
dir	work/acme/app	$P/work/acme/app
dir	work/acme/mono	$P/work/acme/mono
dir	work/acme/mono/feature	$P/work/acme/mono/feature
dir	work/acme/mono/main	$P/work/acme/mono/main
dir	trunk/tool	$P/trunk/tool
dir	trunk/v1.2	$P/trunk/v1.2
dir	personal/app	$P/personal/app
dir	forks/lib	$P/forks/lib
dir	ahmedelgabri/dots	$P/ahmedelgabri/dots
dir	archive/group/x	$P/archive/group/x
dir	archive/group/y	$P/archive/group/y
dir	archive/old	$P/archive/old
dir	archive/old2	$P/archive/old2
dir	archive/old2/wt	$P/archive/old2/wt" "" env HOST_CONFIGS="$WORK/host" mx --list

expect "--list without HOST_CONFIGS" 0 "sess	alpha	$SESSIONS/alpha.lua
sess	broken	$SESSIONS/broken.lua
sess	shared-name	$SESSIONS/shared-name.lua" "" \
	env PROJECTS="$WORK/no-projects" mx --list

# --- launching -------------------------------------------------------------

# launch <session> <root> <mx args...>: mx must create <session> rooted at
# <root> with window 1 active, then fail only at the client switch.
launch() {
	local session=$1 root=$2
	shift 2
	expect "mx $*" 1 "" "$NO_CLIENT" in_tmux mx "$@"
	assert_eq "mx $*: root" "$root" "$(t display-message -p -t "=$session:1.1" '#{pane_current_path}')"
	assert_eq "mx $*: active window" 1 "$(t display-message -p -t "=$session:" '#{window_index}')"
}

cd "$WORK"
expect "ambiguous name" 1 "" "mx: 'app' is ambiguous:
  $P/work/acme/app
  $P/personal/app" in_tmux mx app
if t has-session 2>/dev/null; then
	fail "an ambiguous name started tmux"
fi

launch app "$P/work/acme/app" acme/app

# The first launch creates _shared from shared.lua; mail, rss and HN need
# tools that are not on PATH, so only the directory-backed windows exist.
assert_eq "_shared windows" "2 dotfiles 1 $DOTFILES
2 dotfiles 2 $DOTFILES
3 notes 1 $NOTES_DIR" "$(t list-panes -s -t =_shared -F '#{window_index} #{window_name} #{pane_index} #{pane_current_path}' | sed 1d)"
assert_eq "shared windows linked after project windows" "1 0
2 dotfiles 1
3 notes 1" "$(t list-windows -t =app -F '#{window_index}#{?window_linked, #{window_name},} #{window_linked}')"

# Re-running switches to the existing session without rebuilding it.
launch app "$P/work/acme/app" acme/app
assert_eq "existing session untouched" 3 "$(t display-message -p -t =app: '#{session_windows}')"

launch mono/feature "$P/work/acme/mono/feature" mono/feature
launch mono "$P/work/acme/mono" work/acme/mono
launch tool "$P/trunk/tool" tool
launch v1_2 "$P/trunk/v1.2" v1.2
launch forks/lib "$P/forks/lib" lib
launch archive/old2/wt "$P/archive/old2/wt" old2/wt
launch archive/group/x "$P/archive/group/x" x
launch nomatch "$WORK" nomatch

cd "$P/archive/old"
launch old "$P/archive/old"
cd "$P"
launch dots "$P/ahmedelgabri/dots" --dir ahmedelgabri/dots
launch archive/old "$P/archive/old" --dir "$P/archive/old/"

cd "$WORK"
HOST_CONFIGS="$WORK/host" launch shared-name "$P/personal/app" shared-name
HOST_CONFIGS="$WORK/host" launch beta "$WORK" beta

# --- definitions -----------------------------------------------------------

expect "broken definition" 1 "" \
	"mx: $SESSIONS/broken.lua: windows[1].layout: split must be 'horizontal' or 'vertical'" \
	in_tmux mx broken
if t has-session -t =broken 2>/dev/null; then
	fail "a broken definition created a session"
fi

expect "mx alpha" 1 "" "$NO_CLIENT" in_tmux mx alpha
assert_eq "alpha windows" "1 editor 0
2 build logs 0
3 last 0
4 dotfiles 1
5 notes 1" "$(t list-windows -t =alpha -F '#{window_index} #{window_name} #{window_linked}')"
assert_eq "alpha active window" 1 "$(t display-message -p -t "=alpha:" '#{window_index}')"
assert_eq "alpha panes" "1 1 0 55x24 $P/trunk/tool
1 2 1 24x24 $P/trunk/tool/src
2 1 0 80x8 $HOME
2 2 1 80x7 $DOTFILES
2 3 0 80x7 $P/trunk
3 1 1 80x24 $P/trunk/tool" \
	"$(t list-panes -s -t =alpha -F '#{?window_linked,,#{window_index} #{pane_index} #{pane_active} #{pane_width}x#{pane_height} #{pane_current_path}}' | sed '/^$/d')"

# --- export ----------------------------------------------------------------

for pane in 1.2 2.1 2.2 2.3 3.1; do
	wait_for "alpha:$pane to exec" pane_execed "=alpha:$pane"
done
PROC=$(t display-message -p -t =alpha:1.2 '#{pane_current_command}')

# shellcheck disable=SC2016 # Recorded commands expand when replayed.
{
	record "=alpha:1.1" 'touch "$HOME/replayed one"'
	record "=alpha:2.1" 'touch "$HOME/replayed two"'
	record "=alpha:2.3" 'pwd >"$HOME/replayed three"'
	record "=alpha:3.1" "$(printf 'touch "$HOME/multi one"\ntouch "$HOME/multi \303\251"')"
}

EXPECTED=$(
	cat <<'EOF'
-- Generated by mx --export from session 'alpha'.
-- Windows from shared.lua are omitted; mx adds them to new sessions.
-- Recorded commands are replayed. Review them for secrets before saving.
-- Programs without a recorded command stay as comments.

return {
	root = os.getenv 'HOME' .. '/Projects/trunk/tool',
	windows = {
		{
			label = 'editor',
			layout = {
				split = 'horizontal',
				ratio = 0.6962,
				{
					command = 'touch "$HOME/replayed one"',
				},
				{
					-- running @PROC@ (command not recorded)
					cwd = 'src',
					focus = true,
				},
			},
		},
		{
			label = 'build logs',
			layout = {
				split = 'vertical',
				ratio = 0.3478,
				{
					cwd = os.getenv 'HOME',
					command = 'touch "$HOME/replayed two"',
				},
				{
					split = 'vertical',
					ratio = 0.5,
					{
						-- running @PROC@ (command not recorded)
						cwd = @DOTFILES@,
						focus = true,
					},
					{
						cwd = os.getenv 'HOME' .. '/Projects/trunk',
						command = 'pwd >"$HOME/replayed three"',
					},
				},
			},
		},
		{
			label = 'last',
			layout = {
				command = 'touch "$HOME/multi one"\ntouch "$HOME/multi @E_ACUTE@"',
			},
		},
	},
}
EOF
)
EXPECTED=${EXPECTED//@PROC@/$PROC}
EXPECTED=${EXPECTED//@DOTFILES@/\'$DOTFILES\'}
EXPECTED=${EXPECTED//@E_ACUTE@/$(printf '\303\251')}

expect "--export alpha" 0 "$EXPECTED" "" mx --export alpha

# The pane running mx --export would otherwise export its own invocation.
REPLAY_TWO="					cwd = os.getenv 'HOME',
					command = 'touch \"\$HOME/replayed two\"',"
[[ "$EXPECTED" == *"$REPLAY_TWO"* ]] || fail "expected export lacks the replay line it should drop"
EXPECTED_SELF=${EXPECTED/"$REPLAY_TWO"/"					-- running $PROC (command not recorded)
					cwd = os.getenv 'HOME',"}
SELF_PANE=$(t display-message -p -t =alpha:2.1 '#{pane_id}')
expect "--export from inside alpha" 0 "$EXPECTED_SELF" "" \
	env TMUX_PANE="$SELF_PANE" TMUX="$SOCKET,0,0" mx --export

# tmux running inside a Rex terminal is still tmux.
expect "--export inside tmux inside Rex" 0 "$EXPECTED" "" \
	env REX_SESSION=session:outer REX_BLOCK=block:outer TMUX="$SOCKET,0,0" mx --export alpha
expect "--export outside tmux without session" 64 "" \
	"mx: --export needs a session name outside tmux" mx --export
expect "--export missing session" 1 "" "mx: session not found: nope" mx --export nope

t new-session -d -s linked-only
t link-window -s =_shared:notes -t =linked-only:9
t kill-window -t =linked-only:1
expect "--export only linked windows" 1 "" \
	"mx: session has no unlinked windows: linked-only" mx --export linked-only

# --- export round trip -----------------------------------------------------

mx --export alpha >"$SESSIONS/gamma.lua"
if [[ -e "$HOME/replayed one" || -e "$HOME/replayed two" || -e "$HOME/replayed three" || -e "$HOME/multi one" ]]; then
	fail "commands ran before the exported definition was used"
fi
expect "mx gamma" 1 "" "$NO_CLIENT" in_tmux mx gamma

replayed() {
	[[ -e "$HOME/replayed one" && -e "$HOME/replayed two" && -s "$HOME/replayed three" &&
		-e "$HOME/multi one" && -e "$HOME/multi $(printf '\303\251')" ]]
}
wait_for "recorded commands to replay" replayed
assert_eq "replayed command's pane" "$P/trunk" "$(cat "$HOME/replayed three")"

GEOMETRY='#{?window_linked,,#{window_index} #{window_name} #{window_active} #{pane_index} #{pane_active} #{pane_left}#,#{pane_top} #{pane_width}x#{pane_height} #{pane_current_path}}'
assert_eq "round-trip geometry" \
	"$(t list-panes -s -t =alpha -F "$GEOMETRY" | sed '/^$/d')" \
	"$(t list-panes -s -t =gamma -F "$GEOMETRY" | sed '/^$/d')"
assert_eq "round-trip shared windows" "4 dotfiles
5 notes" "$(t list-windows -t =gamma -F '#{?window_linked,#{window_index} #{window_name},}' | sed '/^$/d')"

# --- migrating old definitions ---------------------------------------------

OLD_SESSIONS="$XDG_CONFIG_HOME/tmux/sessions"
OLD_HOST_SESSIONS="$WORK/host/tmux/sessions"
mkdir -p "$OLD_SESSIONS" "$OLD_HOST_SESSIONS"
printf 'not a definition\n' >"$OLD_SESSIONS/README.md"
cat >"$OLD_SESSIONS/legacy" <<'EOF'
MX_ROOT="$PROJECTS/trunk/tool"

mx_start() {
	tmux rename-window -t "=$MX_SESSION:1" editor
	tmux split-window -h -l 30% -t "=$MX_SESSION:1" -c "$MX_ROOT/src"
	tmux send-keys -t "=$MX_SESSION:1.2" 'touch "$HOME/should not run"' C-m
	tmux new-window -t "=$MX_SESSION:" -n logs -c "$HOME"
	tmux send-keys -t "=$MX_SESSION:logs" -l 'tail -f log'
	tmux send-keys -t "=$MX_SESSION:logs" Enter
	tmux select-pane -t "=$MX_SESSION:1.1"
}
EOF
# shellcheck disable=SC2016 # Definitions expand when mx sources them.
printf 'MX_ROOT="$PROJECTS/personal/app"\n' >"$OLD_HOST_SESSIONS/plain"
# alpha.lua already exists, so its old definition must be left alone.
: >"$OLD_SESSIONS/alpha"

SERVERS_BEFORE=$(t list-sessions -F '#{session_name}' | wc -l)
expect "--migrate" 0 "$OLD_HOST_SESSIONS/plain -> $WORK/host/mx/sessions/plain.lua
$OLD_SESSIONS/legacy -> $SESSIONS/legacy.lua" "mx: skipped $OLD_SESSIONS/alpha: $SESSIONS/alpha.lua exists" \
	env HOST_CONFIGS="$WORK/host" mx --migrate

EXPECTED=$(
	cat <<EOF
-- Converted by mx --migrate from '$OLD_SESSIONS/legacy'.
-- Windows from shared.lua are omitted; mx adds them to new sessions.
-- Recorded commands are replayed. Review them for secrets before saving.
-- Programs without a recorded command stay as comments.

return {
	root = os.getenv 'HOME' .. '/Projects/trunk/tool',
	windows = {
		{
			label = 'editor',
			layout = {
				split = 'horizontal',
				ratio = 0.6962,
				{},
				{
					cwd = 'src',
					command = 'touch "\$HOME/should not run"',
				},
			},
		},
		{
			label = 'logs',
			layout = {
				cwd = os.getenv 'HOME',
				command = 'tail -f log',
			},
		},
	},
}
EOF
)
assert_eq "migrated legacy" "$EXPECTED" "$(cat "$SESSIONS/legacy.lua")"
assert_eq "migrated plain root" "	root = os.getenv 'HOME' .. '/Projects/personal/app'," \
	"$(sed -n '/^\troot = /p' "$WORK/host/mx/sessions/plain.lua")"
[[ ! -e "$HOME/should not run" ]] || fail "--migrate ran a definition's commands"
assert_eq "--migrate left no tmux server behind" "$SERVERS_BEFORE" "$(t list-sessions -F '#{session_name}' | wc -l)"

expect "--migrate again" 0 "" "mx: skipped $OLD_HOST_SESSIONS/plain: $WORK/host/mx/sessions/plain.lua exists
mx: skipped $OLD_SESSIONS/alpha: $SESSIONS/alpha.lua exists
mx: skipped $OLD_SESSIONS/legacy: $SESSIONS/legacy.lua exists" \
	env HOST_CONFIGS="$WORK/host" mx --migrate

expect "mx legacy" 1 "" "$NO_CLIENT" in_tmux mx legacy
assert_eq "migrated session panes" "1 editor 1 1 55x24 $P/trunk/tool
1 editor 2 0 24x24 $P/trunk/tool/src
2 logs 1 1 80x24 $HOME" \
	"$(t list-panes -s -t =legacy -F '#{?window_linked,,#{window_index} #{window_name} #{pane_index} #{pane_active} #{pane_width}x#{pane_height} #{pane_current_path}}' | sed '/^$/d')"
