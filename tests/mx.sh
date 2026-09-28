#!/usr/bin/env bash
# Exercises mx and mx-init against a real tmux server on a private socket.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
BIN_SRC="$ROOT/config/zsh.d/zsh/bin"

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

# Only these tools are reachable, so mx-init cannot find aerc/newsraft/clx on
# the host and launch them.
mkdir -p "$WORK/bin"
for tool in tmux bash awk sed wc basename tail cat env sleep touch mkdir rm diff id chmod; do
	tool_path=$(command -v "$tool")
	ln -s "$tool_path" "$WORK/bin/$tool"
done
# The Nix build sandbox has no /usr/bin/env for the scripts' shebangs.
for script in mx mx-init; do
	printf '#!%s\nexec %q %q "$@"\n' "$WORK/bin/bash" "$WORK/bin/bash" "$BIN_SRC/$script" >"$WORK/bin/$script"
	chmod +x "$WORK/bin/$script"
done

unset TMUX TMUX_PANE HOST_CONFIGS DEBUG
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
SESSIONS="$XDG_CONFIG_HOME/tmux/sessions"
HOST_SESSIONS="$WORK/host/tmux/sessions"

mkdir -p "$SESSIONS" "$HOST_SESSIONS" "$NOTES_DIR" "$DOTFILES"
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

# shellcheck disable=SC2016 # Definitions expand when mx sources them.
printf 'MX_ROOT="$PROJECTS/forks/lib"\n' >"$SESSIONS/shared-name"
# shellcheck disable=SC2016 # Definitions expand when mx sources them.
printf 'MX_ROOT="$PROJECTS/personal/app"\n' >"$HOST_SESSIONS/shared-name"
: >"$HOST_SESSIONS/beta"
mkdir "$SESSIONS/not-a-definition"

cat >"$SESSIONS/alpha" <<'EOF'
MX_ROOT="$PROJECTS/trunk/tool"

mx_start() {
	tmux set-option -t "=$MX_SESSION:" @probe "$MX_SESSION|$MX_ROOT|$PWD"
	tmux rename-window -t "=$MX_SESSION:1" editor
	tmux set-option -p -t "=$MX_SESSION:1.1" @mx_command 'touch "$HOME/replayed one"'
	tmux split-window -h -l 30% -t "=$MX_SESSION:1" -c "$MX_ROOT/src" 'exec sleep 600'
	tmux new-window -t "=$MX_SESSION:" -n 'build logs' -c "$HOME" 'exec sleep 600'
	tmux set-option -p -t "=$MX_SESSION:2.1" @mx_command 'touch "$HOME/replayed two"'
	tmux split-window -v -t "=$MX_SESSION:2" -c "$DOTFILES" 'exec sleep 600'
	tmux split-window -v -t "=$MX_SESSION:2" -c "$PROJECTS/trunk" 'exec sleep 600'
	tmux select-layout -t "=$MX_SESSION:2" even-vertical
	tmux select-pane -t "=$MX_SESSION:2.2"
	tmux select-pane -t "=$MX_SESSION:1.2"
	tmux select-window -t "=$MX_SESSION:2"
	# A failing command must not abort the rest of the layout.
	false
	tmux new-window -t "=$MX_SESSION:" -n after-failure -c "$MX_ROOT" 'exec sleep 600'
	return 1
}
EOF

# --- usage -----------------------------------------------------------------

USAGE="Usage: mx [<name>] | mx --dir <path> | mx --list | mx --pick [query] | mx --export [session]"

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

run env -u PROJECTS mx --list
assert_eq "--list without PROJECTS: status" 1 "$STATUS"
[[ "$OUT" == "" && "$ERR" == *"PROJECTS: PROJECTS is not set" ]] ||
	fail "--list without PROJECTS: got [$OUT] [$ERR]"

# --- listing ---------------------------------------------------------------

P=$PROJECTS
expect "--list" 0 "sess	beta	$HOST_SESSIONS/beta
sess	shared-name	$HOST_SESSIONS/shared-name
sess	alpha	$SESSIONS/alpha
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

expect "--list without HOST_CONFIGS" 0 "sess	alpha	$SESSIONS/alpha
sess	shared-name	$SESSIONS/shared-name" "" \
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

# The first launch creates _shared; mail, rss and HN need tools that are not
# on PATH, so only the directory-backed windows exist.
assert_eq "_shared windows" "2 notes 1 $NOTES_DIR
3 dotfiles 1 $DOTFILES
3 dotfiles 2 $DOTFILES" "$(t list-panes -s -t =_shared -F '#{window_index} #{window_name} #{pane_index} #{pane_current_path}' | sed 1d)"
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

expect "mx alpha" 1 "" "mx: mx_start for alpha failed
$NO_CLIENT" in_tmux mx alpha
assert_eq "mx_start environment" "alpha|$P/trunk/tool|$P/trunk/tool" "$(t show-options -v -t =alpha: @probe)"
assert_eq "alpha windows" "1 editor 0
2 build logs 0
3 after-failure 0
4 dotfiles 1
5 notes 1" "$(t list-windows -t =alpha -F '#{window_index} #{window_name} #{window_linked}')"
assert_eq "alpha active window" 1 "$(t display-message -p -t "=alpha:" '#{window_index}')"

# --- export ----------------------------------------------------------------

for pane in 1.2 2.1 2.2 2.3 3.1; do
	wait_for "alpha:$pane to exec" pane_execed "=alpha:$pane"
done
PROC=$(t display-message -p -t =alpha:1.2 '#{pane_current_command}')

EXPECTED=$(
	cat <<'EOF'
# Generated by mx --export from session alpha.
# Linked windows are omitted; mx appends _shared after mx_start.
# Running commands recorded by zsh are replayed. Review them for secrets before saving this file.
# Commands without tracking metadata remain comments containing only process names.

MX_ROOT="$HOME"/Projects/trunk/tool

mx_start() {
	local window pane
	local -a panes

	window=1
	tmux rename-window -t "=$MX_SESSION:$window" editor
	panes=("$(tmux display-message -p -t "=$MX_SESSION:$window" \#\{pane_index\})")
	tmux send-keys -l -t "=$MX_SESSION:$window.${panes[0]}" -- touch\ \"\$HOME/replayed\ one\"
	tmux send-keys -t "=$MX_SESSION:$window.${panes[0]}" C-m
	pane="$(tmux split-window -d -P -F \#\{pane_index\} -t "=$MX_SESSION:$window" -c "$MX_ROOT"/src)"
	panes+=("$pane")
	# pane 2 command unavailable; current process: @PROC@
	tmux select-layout -t "=$MX_SESSION:$window" @LAYOUT1@
	tmux select-pane -t "=$MX_SESSION:$window.${panes[1]}"

	window="$(tmux new-window -d -P -F \#\{window_index\} -t "=$MX_SESSION:" -n build\ logs -c "$HOME")"
	panes=("$(tmux display-message -p -t "=$MX_SESSION:$window" \#\{pane_index\})")
	tmux send-keys -l -t "=$MX_SESSION:$window.${panes[0]}" -- touch\ \"\$HOME/replayed\ two\"
	tmux send-keys -t "=$MX_SESSION:$window.${panes[0]}" C-m
	pane="$(tmux split-window -d -P -F \#\{pane_index\} -t "=$MX_SESSION:$window" -c @DOTFILES@)"
	panes+=("$pane")
	# pane 2 command unavailable; current process: @PROC@
	pane="$(tmux split-window -d -P -F \#\{pane_index\} -t "=$MX_SESSION:$window" -c "$HOME"/Projects/trunk)"
	panes+=("$pane")
	# pane 3 command unavailable; current process: @PROC@
	tmux select-layout -t "=$MX_SESSION:$window" @LAYOUT2@
	tmux select-pane -t "=$MX_SESSION:$window.${panes[1]}"

	window="$(tmux new-window -d -P -F \#\{window_index\} -t "=$MX_SESSION:" -n after-failure -c "$MX_ROOT")"
	panes=("$(tmux display-message -p -t "=$MX_SESSION:$window" \#\{pane_index\})")
	# pane 1 command unavailable; current process: @PROC@
	tmux select-pane -t "=$MX_SESSION:$window.${panes[0]}"

}
EOF
)
EXPECTED=${EXPECTED//@PROC@/$PROC}
EXPECTED=${EXPECTED//@DOTFILES@/$(printf '%q' "$DOTFILES")}
EXPECTED=${EXPECTED//@LAYOUT1@/$(printf '%q' "$(t display-message -p -t =alpha:1 '#{window_layout}')")}
EXPECTED=${EXPECTED//@LAYOUT2@/$(printf '%q' "$(t display-message -p -t =alpha:2 '#{window_layout}')")}

expect "--export alpha" 0 "$EXPECTED" "" mx --export alpha

# The pane running mx --export would otherwise export its own invocation.
# shellcheck disable=SC2016 # Literal generated code.
REPLAY_TWO='	tmux send-keys -l -t "=$MX_SESSION:$window.${panes[0]}" -- touch\ \"\$HOME/replayed\ two\"
	tmux send-keys -t "=$MX_SESSION:$window.${panes[0]}" C-m'
[[ "$EXPECTED" == *"$REPLAY_TWO"* ]] || fail "expected export lacks the replay lines it should drop"
EXPECTED_SELF=${EXPECTED/"$REPLAY_TWO"/"	# pane 1 command unavailable; current process: $PROC"}
SELF_PANE=$(t display-message -p -t =alpha:2.1 '#{pane_id}')
expect "--export from inside alpha" 0 "$EXPECTED_SELF" "" \
	env TMUX_PANE="$SELF_PANE" TMUX="$SOCKET,0,0" mx --export

expect "--export outside tmux without session" 64 "" \
	"mx: --export needs a session name outside tmux" mx --export
expect "--export missing session" 1 "" "mx: session not found: nope" mx --export nope

t new-session -d -s linked-only
t link-window -s =_shared:notes -t =linked-only:9
t kill-window -t =linked-only:1
expect "--export only linked windows" 1 "" \
	"mx: session has no unlinked windows: linked-only" mx --export linked-only
