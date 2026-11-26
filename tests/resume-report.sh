#!/usr/bin/env bash
# Checks resume-report against the lazygit example of the Program Resume
# Protocol, whose mac is the real hash for its token:
# https://www.superlogical.com/rex/docs/build/program-resume#valid-reports
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT="$ROOT/config/zsh.d/zsh/bin/resume-report"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

# The example's time is fixed, so `date` answers with it.
mkdir "$WORK/bin"
printf '#!/bin/sh\necho 1795543200\n' >"$WORK/bin/date"
chmod +x "$WORK/bin/date"
export PATH="$WORK/bin:$PATH"

expected=$'\e]7577;pid=74877:time=1795543200:argv=bGF6eWdpdA==:cwd=L2hvbWUvdXNlci9zcmMvcHJvamVjdA==:mac=35cb909805c380336efd3689a125acc774a9dec8422a1d21492ebec06ca758e1\e\\'
actual=$(OSC7577_TOKEN=dummy-token-replace-me sh "$SCRIPT" 74877 /home/user/src/project lazygit)
[ "$actual" = "$expected" ] || fail "report differs from the protocol example: $(printf '%q' "$actual")"

actual=$(env -u OSC7577_TOKEN sh "$SCRIPT" 74877 /home/user/src/project lazygit)
[ -z "$actual" ] || fail "reported without a token: $(printf '%q' "$actual")"

echo "resume-report: all tests passed"
