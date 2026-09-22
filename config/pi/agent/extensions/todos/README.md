# Todos

Manage file-based tasks through the `todo` tool or the `/todos [search]` command. Tasks are shared by sessions using the same storage directory rather than stored only in conversation history.

## Interactive manager

Run `/todos` to browse tasks, or `/todos search terms` to prefill the search. Search matches IDs, titles, tags, status, and assignment metadata. The terminal UI offers view, work, refine, close/reopen, release, delete, and clipboard actions.

| Key | Action |
| --- | --- |
| Type | Filter tasks |
| `Up` / `Down` | Select a task |
| `Enter` | Open its action menu |
| `Ctrl+Shift+W` | Put a work-on-task prompt in Pi's editor |
| `Ctrl+Shift+R` | Put a refinement prompt in Pi's editor |
| `Esc` | Close or go back |

Selection keys follow Pi's configured bindings. Work and refine actions do not send the prompt automatically. Refinement asks the agent to clarify missing details before rewriting the task. The detail view supports line and page scrolling; `Enter` selects work. Deletion from the menu requires confirmation.

Without UI, `/todos` prints the task list and ignores the search argument. The `todo` tool remains available for non-interactive use.

## Agent tool

| Action | Input and behavior |
| --- | --- |
| `list` | List non-closed tasks, assigned tasks first |
| `list-all` | Include closed tasks |
| `get` | Read a task by `id` |
| `create` | Require `title`; optionally set `body`, `tags`, and `status` |
| `update` | Require `id`; replace supplied `title`, `body`, `tags`, or `status` |
| `append` | Require `id`; append Markdown `body` |
| `claim` | Assign an open task to the current session |
| `release` | Remove the session assignment |
| `delete` | Delete the task by `id`, without the UI confirmation step |

IDs are eight hexadecimal characters, displayed as `TODO-deadbeef`. Tool calls accept either that form or the raw ID. Tasks default to `open`; `closed` and `done` are treated as closed, and closing clears the assignment.

Claim tasks before working on them and release or close them afterward. `claim` and `release` reject another session's assignment unless `force: true` is supplied. The interactive release action forces release. Assignment is a coordination convention, not write protection: update, append, and delete do not require ownership.

## Storage and cleanup

The default directory is `.pi/todos` relative to the current working directory. Set `PI_TODO_PATH` to use another absolute path or a path relative to that working directory. The directory is created on session start.

Each `<id>.md` file starts with a JSON front-matter object, not YAML, followed by a blank line and optional Markdown. Metadata includes `id`, `title`, `tags`, `status`, `created_at`, and optional `assigned_to_session`. Per-task `.lock` files protect mutations and are released afterward. Locks older than 30 minutes require interactive confirmation before being stolen.

Set cleanup policy in `<todo-directory>/settings.json`:

```json
{
  "gc": true,
  "gcDays": 7
}
```

These are the defaults. On session start, garbage collection deletes closed tasks whose `created_at` is older than the threshold. Age is measured from creation, not completion, so closing an old task can make it eligible immediately on the next startup. Set `gc` to `false` to keep closed tasks indefinitely.

See [extension loading](../README.md#activation).
