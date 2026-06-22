# Claude Code Hooks

This directory contains the hook scripts that are linked into `~/.claude/hooks`
by Home Manager and wired from `config/claude/settings.json`.

## Configured hooks

| Event              | Hook commands                                                           | Purpose                                                                               |
| ------------------ | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| `SessionStart`     | `log-event.sh SessionStart`, `inject-repo-info.sh`                      | Log session startup and inject repository VCS context.                                |
| `PostCompact`      | `log-event.sh PostCompact`, `inject-repo-info.sh`                       | Log compaction and refresh repository VCS context afterward.                          |
| `SessionEnd`       | `log-event.sh SessionEnd`                                               | Log session shutdown.                                                                 |
| `UserPromptSubmit` | `log-event.sh UserPromptSubmit`, `aggregate-prompt.sh UserPromptSubmit` | Log submitted prompts and append project prompts to `PROMPTS.md`.                     |
| `PreToolUse`       | `log-event.sh PreToolUse`; for `Bash`, `validate-bash.sh`               | Log tool calls and block risky Bash commands that touch generated or sensitive paths. |
| `PostToolUse`      | `log-event.sh PostToolUse`                                              | Log tool results.                                                                     |
| `Stop`             | `log-event.sh Stop`, `ccpeek --index-only --skip-scan --quiet ...`       | Log assistant stops and refresh the `ccpeek` index without per-stop secret scans.     |
| `SubagentStop`     | `log-event.sh SubagentStop`                                             | Log subagent completion.                                                              |
| `Notification`     | `log-event.sh Notification`, `terminal-notifier ...`                    | Log notifications and mirror them to macOS Notification Center outside Ghostty.       |
| `PreCompact`       | `log-event.sh PreCompact`                                               | Log compaction before it runs.                                                        |

## Hook scripts

### `log-event.sh`

- **Events**: every configured event that passes the event name as the first
  argument.
- **What it does**: logs the hook event and raw JSON input.
- **Log location**:
  - `$CLAUDE_PROJECT_DIR/.claude/hook-events.jsonl` when Claude is running in a
    project.
  - `~/.claude/hook-events.jsonl` when no project directory is available.
- **Format**: JSON Lines, one JSON object per line.
- **Fields**: `timestamp`, `event`, `project_dir`, `input`.

### `inject-repo-info.sh`

- **Events**: `SessionStart`, `PostCompact`.
- **What it does**: detects whether `$CLAUDE_PROJECT_DIR` is a Jujutsu or Git
  repo and emits `hookSpecificOutput.additionalContext` so Claude knows which
  VCS to use.
- **Jujutsu behavior**: Jujutsu takes priority in colocated repos and the
  injected context reminds Claude to avoid raw `git add`, `git stage`,
  `git history`, and `git commit`.

### `aggregate-prompt.sh`

- **Events**: `UserPromptSubmit`.
- **What it does**: appends the submitted prompt text to
  `$CLAUDE_PROJECT_DIR/PROMPTS.md`, separated by `---` when the file already
  exists.
- **Behavior**: skips global sessions, empty prompts, and invalid project paths.

### `validate-bash.sh`

- **Events**: `PreToolUse` with matcher `Bash`.
- **What it does**: blocks Bash commands that mention generated, dependency,
  IDE, VCS, or secret-ish paths.
- **Blocked patterns**: `node_modules/`, `.env`, `__pycache__/`, `.git/`,
  `dist/`, `build/`, `.next/`, `.astro/`, `.vscode/`, `.idea/`.

## Viewing logs

```bash
# View project-specific logs if in a project
cat .claude/hook-events.jsonl

# View global logs if not in a project
cat ~/.claude/hook-events.jsonl

# Pretty print with jq
cat .claude/hook-events.jsonl | jq

# Filter by event type
cat .claude/hook-events.jsonl | jq 'select(.event == "PreToolUse")'
cat .claude/hook-events.jsonl | jq 'select(.event == "UserPromptSubmit")'

# Count events by type
cat .claude/hook-events.jsonl | jq -r '.event' | sort | uniq -c

# View last 10 events
tail -n 10 .claude/hook-events.jsonl | jq

# Filter by project
cat ~/.claude/hook-events.jsonl | jq 'select(.project_dir == "/path/to/project")'
```

## Hook events used here

- `SessionStart` — when Claude Code starts a session.
- `PostCompact` — after compaction finishes.
- `SessionEnd` — when Claude Code exits a session.
- `UserPromptSubmit` — when you submit a prompt.
- `PreToolUse` — before a tool executes.
- `PostToolUse` — after a tool completes.
- `Stop` — when Claude finishes responding.
- `SubagentStop` — when a subagent finishes.
- `Notification` — during Claude notifications.
- `PreCompact` — before compaction starts.

## Hook behavior

Hooks receive JSON input via stdin and can:

- Exit 0 to allow the operation and optionally print JSON output for events that
  support it.
- Exit 2 from blocking hooks such as `PreToolUse` to block the operation and
  return stderr feedback to Claude.

### Example: block writes to certain files

```bash
#!/bin/bash
input=$(cat)
file_path=$(echo "$input" | jq -r '.file_path // empty')

if [[ "$file_path" == *".env"* ]]; then
	echo "Blocked: Cannot write to .env files" >&2
	exit 2
fi

exit 0
```

### Example: tool-specific hook

Add a matcher to target specific tools:

```json
"PreToolUse": [
  {
    "matcher": "Write",
    "hooks": [
      {
        "type": "command",
        "command": "/path/to/validate-write.sh"
      }
    ]
  }
]
```

## Useful tips

- Use `jq` to parse JSON input properly.
- Keep hooks fast because they block Claude while running.
- Add timeouts for long-running hooks.
- Check `$CLAUDE_*` environment variables for context.
- Test hooks directly with sample JSON before wiring them into `settings.json`.

## Testing hooks

Test a hook manually:

```bash
echo '{"tool_input": {"command": "ls node_modules"}}' | ./validate-bash.sh
```

## Resources

- [Official hooks documentation](https://docs.claude.com/en/docs/claude-code/hooks)
