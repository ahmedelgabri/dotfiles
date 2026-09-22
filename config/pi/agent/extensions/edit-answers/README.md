# `/edit-answer`

Open the latest assistant response as Markdown in an external editor, then place the edited text in Pi's input editor. Run `/edit-answer` or press `Ctrl+Shift+V` in Pi's terminal UI.

## Workflow

The slash command waits for Pi to become idle, then reads the latest assistant message with text on the current branch. The shortcut reads the current branch without that wait. Thinking and tool-call blocks are not included, and incomplete responses are not rejected.

The response is written to `<system-temp>/pi-edit-answer/answer-<timestamp>.md`. Pi suspends its terminal UI while the editor runs. A successful editor exit copies the file contents into Pi's input editor for review and manual submission. A nonzero exit leaves the input unchanged. Temporary Markdown files are retained.

## Editor selection

The extension runs `$EDITOR`, defaulting to `vim`. Set it to an executable name or path, not a shell command with arguments. It does not consult `$VISUAL` or Pi's `externalEditor` setting.

Unlike [`/answer`](../answer/README.md), this command makes no model request to extract questions and does not submit the edited text automatically.

See [extension loading](../README.md#activation).
