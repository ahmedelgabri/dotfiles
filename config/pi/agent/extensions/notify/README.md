# Terminal notifications

Send a `Pi` notification with the body `Ready for input` when the agent settles.
The `agent_settled` event waits until automatic retries, compaction retries, and
queued continuations have finished. There are no commands or extension settings.

## Terminal support

- When `REX_SESSION` is set, send nothing. Rex shows agent notifications itself.
- When `KITTY_WINDOW_ID` is set, use Kitty's OSC 99 notification protocol.
- Otherwise, use OSC 777, supported by terminals such as Ghostty, WezTerm, and
  rxvt-unicode.
- When `TMUX` is set, wrap the escape sequences for tmux passthrough. tmux must
  allow passthrough; this repository's tmux configuration enables it.

Notification visibility depends on the terminal and operating-system
notification settings. No separate desktop notification executable is used.

Notifications are sent only in the interactive TUI. Print, JSON, and RPC runs, such as `/loop` runs, stay silent, so no escape sequence reaches their captured output.

## Tests

From `config/pi/agent/extensions`, `node --test notify/notify.test.ts` checks every run mode and starts real Pi in print and RPC mode against a loopback model. `PI_E2E_MODEL=anthropic/claude-haiku-4-5 node --test notify/notify.e2e.test.ts` repeats the print-mode check with the real agent directory and model.

See [extension loading](../README.md#activation).
