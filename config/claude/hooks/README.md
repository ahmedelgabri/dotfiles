# Claude Code Hooks

This directory contains the hook scripts that are linked into `~/.claude/hooks`
by Home Manager and wired from `config/claude/settings.json`.

## Configured hooks

| Event                | Hook commands                                                                                             | Purpose                                                                                                                             |
| -------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `SessionStart`       | `log-event.sh SessionStart`, `inject-repo-info.sh`, `rex __internal session-start`, `mx-resume.sh claude` | Log session startup, inject repository VCS context, tell Claude its Rex session and pane, record how to resume after a Rex restart. |
| `PostCompact`        | `inject-repo-info.sh`                                                                                     | Restore repository VCS context after compaction.                                                                                    |
| `SessionEnd`         | `log-event.sh SessionEnd`                                                                                 | Log session shutdown.                                                                                                               |
| `PostToolUse`        | `zh record claude` (matcher `Bash`)                                                                       | Record Bash commands in the agent history.                                                                                          |
| `PostToolUseFailure` | `zh record claude` (matcher `Bash`)                                                                       | Record Bash commands whose call failed (denied, tool error).                                                                        |
| `Stop`               | `run-ccpeek.sh`                                                                                           | Refresh the `ccpeek` index.                                                                                                         |
| `Notification`       | `log-event.sh Notification`, `notify.sh`                                                                  | Log notifications, mirror them to a desktop notification.                                                                           |

The `rex __internal session-start` hook is the one `rex skill setup` installs, with session naming off (`--feature-session-naming=false`), so Claude does not rename the Rex session. It is checked in because `settings.json` is managed by this repository, so setup finds it current and leaves the file alone; `config/codex/hooks.json` carries the Codex copy.

## Hook scripts

### `log-event.sh`

- **Events**: `SessionStart`, `SessionEnd`, `Notification`, passed as the first
  argument.
- **What it does**: logs the hook event and raw JSON input. Only these events
  are logged because Claude Code's transcripts under `~/.claude/projects` never
  record their payloads (the `SessionStart` `source`, the `SessionEnd` `reason`,
  the `Notification` `message` and `notification_type`). Prompts, tool calls and
  results, stops, subagents, and compaction are already in the transcripts, and
  prompts also in `~/.claude/history.jsonl`. To inspect another event's payload
  while debugging a hook, wire `log-event.sh <Event>` for that event
  temporarily.
- **Log location**:
  - `~/.claude/logs/<project-slug>/hook-events.jsonl` when Claude is running in
    a project — the slug encodes `$CLAUDE_PROJECT_DIR` the same way Claude
    Code's own `~/.claude/projects` does (`/` and `.` become `-`). Logs live
    outside the project tree so archives, backups, and build contexts never ship
    them.
  - `~/.claude/logs/hook-events.jsonl` when no project directory is available.
- **Format**: JSON Lines, one JSON object per line.
- **Fields**: `timestamp`, `event`, `project_dir`, `input`.

### `inject-repo-info.sh`

- **Events**: `SessionStart` and `PostCompact` in Claude Code. Codex wires it
  from `config/codex/hooks.json`.
- **What it does**: detects whether `$CLAUDE_PROJECT_DIR` is a Jujutsu or Git
  repo and emits `hookSpecificOutput.additionalContext` so the agent knows which
  VCS to use. `PostCompact` restores this context after compaction.

### `mx-resume.sh`

- **Events**: `SessionStart`, which also fires after `/clear` and `--resume`, so the file follows the current session. Codex runs it too, as `mx-resume.sh codex` from `config/codex/hooks.json`, and asks you to approve it once with `/hooks`.
- **What it does**: in a Rex pane, writes `cd -- <cwd> && claude --resume <session id>` (or `codex resume <session id>`) to `$_MX_RESUME_FILE`. After a Rex server restart, the pane's new zsh puts that line on the prompt instead of the command that started the agent, which would open a new session. See the restore paragraph in [`nix/pkgs/mx/README.md`](../../../nix/pkgs/mx/README.md).
- **Behavior**: a no-op outside a Rex pane, and for an agent that the pane's shell did not start directly, such as one started by another agent, so a nested agent does not take over the pane. The resume line keeps no other flags, such as `--permission-mode`.

### `zh` (from `nix/pkgs/zh`)

- **Events**: `PostToolUse` and `PostToolUseFailure`, matcher `Bash`; Codex
  wires the same command from `config/codex/hooks.json`.
- **What it does**: appends the Bash command, its working directory, the session
  id, Claude's description of the call, and whether it arrived through
  `PostToolUseFailure` to `$ZDOTDIR/.zh.db`, the agent-only history the zsh
  Ctrl-R widget searches under CTRL-A and CTRL-D. `PostToolUse` fires for every
  command that ran, whatever its exit status; `PostToolUseFailure` fires for
  calls that did not run (denied, tool error), so the history also shows what
  an agent tried. A call stopped with Esc sends neither event, so it is not
  recorded. Commands matching credential patterns are dropped.
- **Failure mode**: a bad payload or unwritable file exits 1 with a message on
  stderr; PostToolUse hooks only warn on a non-zero exit, so the agent is never
  blocked.

### `run-ccpeek.sh`

- **Events**: `Stop`.
- **What it does**: refreshes the `ccpeek` index; exits quietly when `ccpeek` is
  not installed. `settings.json` is shared across platforms, so the script
  resolves the log location at runtime.
- **Log location**: `~/Library/Logs` on macOS, `$XDG_STATE_HOME` (default
  `~/.local/state`) elsewhere.

### `notify.sh`

- **Events**: `Notification`.
- **What it does**: mirrors the notification message to a desktop notification —
  `terminal-notifier` on macOS or `notify-send` elsewhere — picking the notifier
  at runtime because `settings.json` is shared across platforms.
- **Behavior**: a no-op inside Rex (`REX_SESSION` set), which shows Claude's
  notifications itself, when no notifier is installed, or when the message is
  empty.

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
cat "$LOGS"/hook-events.jsonl | jq 'select(.event == "Notification")'
cat "$LOGS"/hook-events.jsonl | jq 'select(.event == "SessionEnd")'

# Count events by type
cat "$LOGS"/hook-events.jsonl | jq -r '.event' | sort | uniq -c

# View last 10 events
tail -n 10 "$LOGS"/hook-events.jsonl | jq

# Search across all projects
cat ~/.claude/logs/*/hook-events.jsonl | jq 'select(.project_dir == "/path/to/project")'
```

## Hook events used here

- `SessionStart` — when Claude Code starts a session.
- `PostCompact`: after Claude Code compacts the conversation.
- `SessionEnd` — when Claude Code exits a session.
- `UserPromptSubmit` — when you submit a prompt.
- `PreToolUse` — before a tool executes.
- `PostToolUse` — after a tool completes.
- `PostToolUseFailure` — after a tool call fails.
- `PermissionRequest` — when a tool call waits on a permission prompt.
- `Elicitation` — when an MCP server asks the user a question.
- `ElicitationResult` — when the user answers an MCP elicitation.
- `Stop` — when Claude finishes responding.
- `StopFailure` — when a turn ends in an error.
- `Notification` — during Claude notifications.

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
echo '{"message": "sample notification"}' | CLAUDE_PROJECT_DIR=$PWD ./log-event.sh Notification
```

## Resources

- [Official hooks documentation](https://docs.claude.com/en/docs/claude-code/hooks)
