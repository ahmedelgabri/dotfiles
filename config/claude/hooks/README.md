# Claude Code Hooks

This directory contains the hook scripts that are linked into `~/.claude/hooks`
by Home Manager and wired from `config/claude/settings.json`.

## Configured hooks

| Event              | Hook commands                                                                             | Purpose                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `SessionStart`     | `log-event.sh SessionStart`, `inject-repo-info.sh`, `tap state idle --agent claude`       | Log session startup, inject repository VCS context, publish idle agent status.   |
| `PostCompact`      | `log-event.sh PostCompact`, `inject-repo-info.sh`                                         | Log compaction and refresh repository VCS context afterward.                     |
| `SessionEnd`       | `log-event.sh SessionEnd`, `tap state clear --agent claude`                               | Log session shutdown and clear the published agent status.                       |
| `UserPromptSubmit` | `log-event.sh UserPromptSubmit`, `aggregate-prompt.sh UserPromptSubmit`, `tap state running --agent claude` | Log submitted prompts, append them to the central `PROMPTS.md`, mark agent busy. |
| `PreToolUse`       | `log-event.sh PreToolUse`, `tap state running --agent claude`                             | Log tool calls and mark the agent busy.                                          |
| `PostToolUse`      | `log-event.sh PostToolUse`                                                                | Log tool results.                                                                |
| `Stop`             | `log-event.sh Stop`, `run-ccpeek.sh`, `tap state idle --agent claude`                     | Log assistant stops, refresh the `ccpeek` index, mark the agent idle.            |
| `SubagentStop`     | `log-event.sh SubagentStop`                                                               | Log subagent completion.                                                         |
| `Notification`     | `log-event.sh Notification`, `notify.sh`, `tap state notification --agent claude`         | Log notifications, mirror them to a desktop notification, publish the status.    |
| `PreCompact`       | `log-event.sh PreCompact`                                                                 | Log compaction before it runs.                                                   |

The `tap state` entries publish the agent's activity state so other tooling
(e.g. the tmux statusline) can display it.

## Hook scripts

### `log-event.sh`

- **Events**: every configured event that passes the event name as the first
  argument.
- **What it does**: logs the hook event and raw JSON input.
- **Log location**:
  - `~/.claude/logs/<project-slug>/hook-events.jsonl` when Claude is running in
    a project — the slug encodes `$CLAUDE_PROJECT_DIR` the same way Claude
    Code's own `~/.claude/projects` does (`/` and `.` become `-`). Logs live
    outside the project tree so archives, backups, and build contexts never
    ship them.
  - `~/.claude/logs/hook-events.jsonl` when no project directory is available.
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
  `~/.claude/logs/<project-slug>/PROMPTS.md` (same slug scheme as
  `log-event.sh`), separated by `---` when the file already exists.
- **Behavior**: skips global sessions, empty prompts, and invalid project paths.

### `run-ccpeek.sh`

- **Events**: `Stop`.
- **What it does**: refreshes the `ccpeek` index; exits quietly when `ccpeek` is not installed. `settings.json` is shared across platforms, so the script resolves the log location at runtime.
- **Log location**: `~/Library/Logs` on macOS, `$XDG_STATE_HOME` (default `~/.local/state`) elsewhere.

### `notify.sh`

- **Events**: `Notification`.
- **What it does**: mirrors the notification message to a desktop notification — `terminal-notifier` on macOS, `notify-send` elsewhere — picking the notifier at runtime because `settings.json` is shared across platforms.
- **Behavior**: skipped inside Ghostty (`GHOSTTY_BIN_DIR` set), which surfaces notifications itself; a no-op when no notifier is installed or the message is empty.

## Viewing logs

```bash
# Resolve the current project's log dir
LOGS=~/.claude/logs/"${PWD//[\/.]/-}"

# View project-specific logs
cat "$LOGS"/hook-events.jsonl

# View global logs (sessions without a project directory)
cat ~/.claude/logs/hook-events.jsonl

# Pretty print with jq
cat "$LOGS"/hook-events.jsonl | jq

# Filter by event type
cat "$LOGS"/hook-events.jsonl | jq 'select(.event == "PreToolUse")'
cat "$LOGS"/hook-events.jsonl | jq 'select(.event == "UserPromptSubmit")'

# Count events by type
cat "$LOGS"/hook-events.jsonl | jq -r '.event' | sort | uniq -c

# View last 10 events
tail -n 10 "$LOGS"/hook-events.jsonl | jq

# Search across all projects
cat ~/.claude/logs/*/hook-events.jsonl | jq 'select(.project_dir == "/path/to/project")'
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
echo '{"prompt": "sample prompt"}' | CLAUDE_PROJECT_DIR=$PWD ./log-event.sh UserPromptSubmit
```

## Resources

- [Official hooks documentation](https://docs.claude.com/en/docs/claude-code/hooks)
