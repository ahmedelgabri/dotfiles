# `/total-cost`

Show recorded model costs across saved Pi sessions, grouped by UTC month with message and session counts. Run `/total-cost` in the terminal UI and press `Enter` or `Esc` to close the report. Print and JSON modes produce a plain-text report.

## Data and scope

The extension scans `.jsonl` files one project-directory level below `$PI_CODING_AGENT_DIR/sessions`, defaulting to `~/.pi/agent/sessions`. It does not read a separate `--session-dir` or `PI_CODING_AGENT_SESSION_DIR` location.

Costs come from positive, finite `usage.cost.total` values on assistant messages and standalone `usage` entries, including cache warming. Only contributing assistant messages increment the message count. Session counts identify contributing files; a session can appear in multiple monthly rows but is counted once in the overall total.

Months use the entry timestamp, with the assistant message timestamp as a fallback. Unreadable files, malformed lines, invalid timestamps, and zero-cost entries are skipped. The interactive report includes file counts and the number of unreadable files skipped.

This is a summary of stored estimates, not a billing statement. It scans entire files rather than only active branches, does not deduplicate history copied into separate session files, and does not separately count usage attached to tool-result messages. Ephemeral sessions have no saved file to scan. No model or billing API request is made.

See [extension loading](../README.md#activation).
