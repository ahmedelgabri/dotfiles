# Agent history

Record commands issued through Pi's `bash` tool in the agent-only history database, `$ZDOTDIR/.agent_history.db`, with agent `pi`. This runs automatically and adds no command, shortcut, or tool.

## Requirements and behavior

`agent-history` (from `nix/pkgs/agent-history`) must be on PATH. The extension listens on `tool_result`, which Pi emits only for tool calls that actually executed: calls blocked by another extension, or aborted before the process started, produce no record, while commands that ran and failed are recorded like successful ones. This matches the `PostToolUse` hooks used for Claude Code and Codex; pi has no equivalent of Claude's `PostToolUseFailure`, so calls that never ran are not recorded here.

Each record uses the Pi working directory and the Pi session id, so `agent-history list --session ID` can show one session's commands. The recorder is spawned with a ten-second timeout and the payload on stdin; when it fails, its message is shown as a Pi warning and the tool result is left untouched. It does not record the separate `!` and `!!` user-shell events.

See [extension loading](../README.md#activation).
