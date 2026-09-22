# `/md`

Save the latest assistant response on the current branch as a Markdown file without another model request.

## Usage

| Command | Destination |
| --- | --- |
| `/md` | `agent-message-<UTC-message-timestamp>.md` in the working directory |
| `/md notes/review` | `notes/review.md` relative to the working directory |
| `/md "notes/review summary.md"` | A path containing spaces |
| `/md ~/Desktop/` | A timestamped file in an existing directory |

Absolute paths and `~` are supported. A missing `.md` extension is appended, and missing parent directories are created. Directory destinations must already exist; a nonexistent path is treated as a filename.

The command waits for Pi to become idle and exports text blocks only, excluding thinking and tool calls. It can export an incomplete response, in which case the save notification includes the stop reason. The file ends with a newline.

Existing destinations require overwrite confirmation when UI is available. In print or JSON mode, overwrites are refused. Writes use a temporary file followed by rename. Exported files are created with mode 0644, subject to the process umask, so choose a private destination for sensitive responses.

See [extension loading](../README.md#activation).
