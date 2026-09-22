# `/answer`

Extract questions from the latest completed assistant response and answer them in an interactive form. Run `/answer` or press `Ctrl+.` in Pi's terminal UI.

## Workflow

The extension makes a separate model request to extract questions and any supporting context. It prefers authenticated `openai-codex/gpt-5.6-luna`, then `anthropic/claude-sonnet-5`, then the current model. A selected model and working Pi credentials are required. Extraction can incur model usage; it is not a local text parser.

| Key | Action |
| --- | --- |
| `Tab` / `Shift+Tab` | Next / previous question |
| `Enter` | Next question, or open submission confirmation on the last question |
| `Shift+Enter` | Insert a newline |
| `Up` / `Down` | Previous / next question when the answer editor is empty |
| `Esc` / `Ctrl+C` | Cancel |

At the confirmation prompt, `Enter` or `y` submits all answers; `Esc`, `Ctrl+C`, or `n` returns to the form. Unanswered questions are marked `(no answer)`. Submission adds the compiled Q&A to the conversation and triggers an agent turn immediately, rather than placing a draft in the editor.

The command refuses an incomplete latest assistant response. If no questions are found, it only shows a notification. Use [`/edit-answer`](../edit-answers/README.md) to annotate the response manually without an extraction request.

See [extension loading](../README.md#activation).
