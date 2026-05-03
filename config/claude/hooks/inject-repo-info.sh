#!/usr/bin/env bash
set -ue -o pipefail

# Inject repo VCS info (Jujutsu vs Git) into the SessionStart context.
# Inspired by config/pi/agent/extensions/jj-guard.ts.

cwd="${CLAUDE_PROJECT_DIR:-$PWD}"

emit_context() {
	jq -n --arg ctx "$1" '{
		hookSpecificOutput: {
			hookEventName: "SessionStart",
			additionalContext: $ctx
		}
	}'
}

# Jujutsu takes priority — colocated repos have both .jj and .git.
if command -v jj >/dev/null 2>&1 && (cd "$cwd" && jj --ignore-working-copy root >/dev/null 2>&1); then
	emit_context "This repository uses Jujutsu (\`jj\`). Avoid raw \`git add\`, \`git stage\`, \`git history\`, and \`git commit\` — use \`jj\` commands for any repository-changing workflows."
elif git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	emit_context "This repository uses Git."
fi

exit 0
