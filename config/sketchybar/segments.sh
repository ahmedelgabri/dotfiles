# shellcheck shell=bash
# shellcheck disable=SC2034 # the scripts that source this file use its variables
# Sourced by the SketchyBar plugins and helpers. Each segment reuses a tmux
# status script and turns its tmux markup into a colour name plus plain text.

# launchd starts SketchyBar, and so its plugins, without the login shell's PATH.
PATH="$HOME/.config/zsh/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS:$PATH"
export PATH

# The bar must never start a Rex server by itself.
export REX_AUTOSTART=0

TMUX_SCRIPTS="$HOME/.config/tmux/scripts"

# Both sides build their separators from these properties so they match.
SEPARATOR=(label=⦁ label.color=0xff303030 padding_left=0 padding_right=0)

# agents.sh lists the items of working agents here for spinner.sh to animate.
AGENTS_WORKING_FILE="${TMPDIR:-/tmp}/sketchybar-agents-working"
SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)

# The helpers run in the background from sketchybarrc, which a reload runs
# again. Returns 1 when a copy of helper $1 is already running.
single_instance() {
	local pidfile="${TMPDIR:-/tmp}/sketchybar-$1.pid" pid
	if pid="$(cat "$pidfile" 2>/dev/null)" && ps -p "$pid" -o command= 2>/dev/null | grep -q "$1"; then
		return 1
	fi
	echo $$ >"$pidfile"
}

# plain-dark ANSI slots, see config/kitty/themes/plain-dark.conf
palette_hex() {
	case "$1" in
	black | themedarkgrey) echo 303030 ;;
	red) echo cc6666 ;;
	green) echo b5bd68 ;;
	yellow) echo f0c674 ;;
	blue) echo 81a2be ;;
	magenta) echo b294bb ;;
	cyan) echo 8abeb7 ;;
	brightblack) echo 666666 ;;
	brightred) echo f2777a ;;
	*) echo c5c8c6 ;;
	esac
}

# Prints "<colour>\t<text>". The colour is the first #[fg=...] the script
# printed, so status-driven colours (red incident, low battery) survive.
# The fallback must be non-empty: `read` with a tab IFS skips an empty field.
parse_tmux() {
	local fallback="$1" raw color text
	raw="$(cat)"
	color="$(sed -nE 's/^[^#]*#\[fg=([a-z]+)\].*/\1/p' <<<"$raw" | head -n 1)"
	text="$(sed -E 's/#\[[^]]*\]//g; s/[[:space:]]*⦁[[:space:]]*$//; s/^[[:space:]]+//; s/[[:space:]]+$//' <<<"$raw")"
	printf '%s\t%s\n' "${color:-$fallback}" "$text"
}

# Fallback colours match the #[fg=...] wrappers in tmux.conf's status-right.
run_segment() {
	local fallback=default
	local -a cmd
	case "$1" in
	npm) cmd=("$TMUX_SCRIPTS/tmux-statuspage" npm wyvgptkd90hm '\uE616') ;;
	github) cmd=("$TMUX_SCRIPTS/tmux-statuspage" github kctbh9vrtdwd '\uE709') ;;
	weather) cmd=("$TMUX_SCRIPTS/tmux-weather") ;;
	battery) cmd=("$TMUX_SCRIPTS/tmux-battery") ;;
	wifi) cmd=(wifi) fallback=themedarkgrey ;;
	# next-prayer prints tmux markup instead of ANSI only when $TMUX is set.
	prayer) cmd=(env TMUX=1 "$TMUX_SCRIPTS/get-prayer") fallback=brightblack ;;
	cairo) cmd=(env TZ=:/usr/share/zoneinfo/Africa/Cairo date '+CAI: %H:%M') fallback=themedarkgrey ;;
	date) cmd=(date '+%A, %d %b %Y %H:%M') fallback=brightblack ;;
	*) return 1 ;;
	esac
	"${cmd[@]}" 2>/dev/null | parse_tmux "$fallback"
}
