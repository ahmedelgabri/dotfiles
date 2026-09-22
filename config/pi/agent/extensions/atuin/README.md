# Atuin history

Record commands issued through Pi's `bash` tool in Atuin with author `pi` and author kind `agent`. This runs automatically and adds no command, shortcut, or tool.

## Requirements and behavior

`atuin` must be on PATH and support `history start --author pi --author-kind agent`. Each history entry uses the Pi working directory and is closed when tool execution finishes, including when another extension blocks the call.

Successful calls are recorded with exit code 0. Failed calls use the exit code reported in the Bash result, 130 for cancellation, 124 for timeout, or 1 when no code can be recovered. Atuin calls have a ten-second timeout; Atuin failures do not prevent tool execution.

The extension observes tool events rather than replacing `bash`, so it can coexist with another extension's shell backend. It does not record the separate `!` and `!!` user-shell events.

Commands are stored in your Atuin history. Avoid putting secrets directly in command arguments. This file is maintained here instead of using `atuin hook install pi` because the dotfiles relocate Pi's agent directory with `PI_CODING_AGENT_DIR`.

`atuin hook install pi` may create a top-level `extensions/atuin.ts`. Do not load it alongside `atuin/index.ts`: Pi discovers both and records each Bash tool call twice. Keep the directory entrypoint and remove the duplicate; the directory version uses this repository's Pi imports and configuration.

See [extension loading](../README.md#activation).
