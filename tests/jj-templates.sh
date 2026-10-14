#!/usr/bin/env bash
# Renders the templates from config/jj/config.toml with real jj against a
# temporary repository, checking that the author is shown only when it is not
# the configured user, and then with both name and email.
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

export HOME="$WORK/home"
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
cat >"$WORK/test.toml" <<'EOF'
user.name = "Ahmed El Gabri"
user.email = "ahmed@example.invalid"
signing.behavior = "drop"
ui.color = "never"
ui.paginate = "never"
EOF
export JJ_CONFIG="$ROOT/config/jj/config.toml:$WORK/test.toml"

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

has() {
	[[ "$2" == *"$3"* ]] || fail "$1: expected '$3' in: $2"
}

lacks() {
	[[ "$2" != *"$3"* ]] || fail "$1: unexpected '$3' in: $2"
}

# Picks one line by pattern without a pipe, so pipefail cannot trip on SIGPIPE.
line() {
	local pattern=$1 text=$2 l
	while IFS= read -r l; do
		[[ "$l" == *"$pattern"* ]] && printf '%s\n' "$l" && return 0
	done <<<"$text"
	fail "no line matching '$pattern' in: $text"
}

as() {
	local name=$1 email=$2
	shift 2
	jj --config "user.name=\"$name\"" --config "user.email=\"$email\"" "$@" >/dev/null 2>&1
}

# jj keeps the author of whoever created a commit, so each one starts with
# `jj new` as its author, who also snapshots the file: a rewrite by anyone else
# would fill in an empty author email.
commit() {
	local bookmark=$1 content=$2 name=$3 email=$4
	as "$name" "$email" new -m "$bookmark"
	echo "$content" >>f
	as "$name" "$email" bookmark create "$bookmark" -r @
}

REPO="$WORK/repo"
jj git init --colocate "$REPO" >/dev/null 2>&1
cd "$REPO"

commit mine one "Ahmed El Gabri" "ahmed@example.invalid"
commit theirs two "Jane Doe" "jane@example.invalid"
commit alt three "Ahmed El Gabri" "ahmed@personal.invalid"
commit handoff four "Jane Doe" "jane@example.invalid"
# Rewording as the configured user keeps Jane as author but makes me committer.
# It runs before noemail exists, because rebasing noemail would fill its email.
jj describe -r handoff -m "handoff (reworded)" >/dev/null 2>&1
commit noemail five "Ahmed El Gabri" ""

# --- compact log ----------------------------------------------------------------

out=$(jj log --no-graph -r mine)
lacks "compact mine" "$out" "Ahmed El Gabri"
out=$(jj log --no-graph -r alt)
has "compact alt" "$out" "Ahmed El Gabri <ahmed@personal.invalid>"
out=$(jj log --no-graph -r theirs)
has "compact theirs" "$out" "Jane Doe <jane@example.invalid>"

# --- oneline log ----------------------------------------------------------------

out=$(jj log --no-graph -r mine -T builtin_log_oneline)
lacks "oneline mine" "$out" "Ahmed El Gabri"
[[ "$out" != *- ]] || fail "oneline mine: dangling separator: $out"
out=$(jj log --no-graph -r theirs -T builtin_log_oneline)
has "oneline theirs" "$out" "- Jane Doe <jane@example.invalid>"
out=$(jj log --no-graph -r alt -T builtin_log_oneline)
has "oneline alt" "$out" "- Ahmed El Gabri <ahmed@personal.invalid>"

# --- gr alias -------------------------------------------------------------------

out=$(jj oneline)
lacks "gr mine" "$(line ' mine' "$out")" " - "
has "gr theirs" "$(line ' theirs' "$out")" " - Jane Doe <jane@example.invalid>"
has "gr alt" "$(line ' alt' "$out")" " - Ahmed El Gabri <ahmed@personal.invalid>"

# --- show -----------------------------------------------------------------------

out=$(jj show -r mine)
author=$(line 'Author' "$out")
committer=$(line 'Committer' "$out")
[[ "$author" == "Author   : ("* ]] || fail "show mine author: $author"
[[ "$committer" == "Committer: ("* ]] || fail "show mine committer: $committer"
out=$(jj show -r handoff)
has "show handoff author" "$(line 'Author' "$out")" "Jane Doe <jane@example.invalid> ("
committer=$(line 'Committer' "$out")
[[ "$committer" == "Committer: ("* ]] || fail "show handoff committer: $committer"
out=$(jj show -r alt)
has "show alt author" "$(line 'Author' "$out")" "Ahmed El Gabri <ahmed@personal.invalid> ("

# --- file annotate --------------------------------------------------------------

out=$(jj file annotate -r alt f)
# A 32-column author field: blank for me, padded when it fits, truncated with
# an ellipsis when it does not.
re_mine='^[a-z]{8,} {34}[0-9]{4}-'
re_theirs='^[a-z]{8,} Jane Doe <jane@example\.invalid>  [0-9]{4}-'
re_alt='^[a-z]{8,} Ahmed El Gabri <ahmed@[^ ]*… [0-9]{4}-'
[[ "$(line ': one' "$out")" =~ $re_mine ]] || fail "annotate mine: $out"
[[ "$(line ': two' "$out")" =~ $re_theirs ]] || fail "annotate theirs: $out"
[[ "$(line ': three' "$out")" =~ $re_alt ]] || fail "annotate alt: $out"

# --- host without a configured email --------------------------------------------

# Empty fields never match, so the NO EMAIL warning still shows.
out=$(jj --config 'user.email=""' log --no-graph -r noemail -T builtin_log_oneline)
has "unconfigured oneline" "$out" "- Ahmed El Gabri <NO EMAIL>"
out=$(jj --config 'user.email=""' log --no-graph -r noemail)
has "unconfigured compact" "$out" "Ahmed El Gabri <NO EMAIL>"

echo "jj-templates: ok"
