# `/loop`

Run a recurring prompt in a detached tmux session. Each iteration starts a fresh `pi --no-session -p` process with the task and, when available, the previous report. It does not inherit the owner's conversation history.

## Start a loop

```text
/loop 30m Check CI and report failures without changing anything
/loop daily 09:00 Summarize pending reviews without posting comments
/loop every day at 9AM Summarize pending reviews without posting comments
```

`/loop` or `/loop start` opens a schedule prompt and a multiline task editor when UI is available. `/loop PROMPT` defaults to 30 minutes. `/loop start [SCHEDULE] PROMPT` is the explicit form, useful when the prompt begins with a subcommand name.

Intervals accept `s`, `m`, `h`, and `d`, including fractional values, between 30 seconds and 30 days. Interval loops run immediately. Daily schedules accept 12-hour or 24-hour times and wait for the next occurrence on the machine's local clock. There is no per-loop timezone option.

Runs do not overlap or replay a backlog of missed ticks. Workers recheck the clock while sleeping so system suspend does not add a full extra sleep interval. Daily times that do not exist during a daylight-saving transition are skipped.

## Manage loops

| Command | Action |
| --- | --- |
| `/loop list` | List all saved loops |
| `/loop status [ID]` | Show schedule, run state, working directory, and file paths |
| `/loop show [ID]` | Open the latest report |
| `/loop logs [ID]` | Open the worker lifecycle log |
| `/loop commands [ID]` | Open the tool-call audit log |
| `/loop events [ID]` | Open the full event log |
| `/loop stop [ID]` | Stop one loop, retaining its files |
| `/loop stop all` | Stop all active loops, including those owned by other sessions |
| `/loop restart [ID]` | Restart a stopped loop and assign it to the current Pi session |
| `/loop toggle` or `/loop-toggle` | Collapse or expand the active loop panel |
| `/loop help` | Show command syntax |

`Ctrl+Alt+L` also toggles the panel. Omit `ID` only when exactly one saved loop belongs to the current session. Explicit references can use an unambiguous ID prefix or tmux session-name suffix.

Completed reports are polled every five seconds for loops owned by the open session. Reports are persisted as display-only session entries; they do not automatically trigger a model response. The panel starts collapsed and remembers its state. If several iterations finish while the owner is closed, the latest report is delivered on return; `runs.log` retains the report history subject to log trimming.

## Requirements and lifetime

`tmux`, `pi`, `/bin/bash`, and the worker's standard Unix utilities must be available. Pi does not need to be launched inside tmux; the extension creates detached sessions named `pi-loop-<ID>`.

The loop saves its working directory, provider, model, and thinking level at creation. Fresh Pi processes must be able to resolve that model and its credentials. Restarting refreshes the Pi executable path and PATH but retains the saved task, schedule, and model selection.

Closing or reloading the owner does not stop the worker. Loops continue until stopped or their tmux server exits. They do not automatically restart after reboot. Use `/loop stop` before removing a loop's state directory.

## State and privacy

Storage is `${XDG_STATE_HOME:-$HOME/.local/state}/pi-loop`, overridden by `PI_LOOP_STATE_DIR`. Each loop directory contains:

| File | Contents |
| --- | --- |
| `config.json`, `prompt.md` | Saved configuration and task |
| `latest.md`, `runs.log` | Latest report and accumulated reports |
| `state.env` | Iteration, timing, exit code, and next-run state |
| `worker.sh`, `launch.sh` | Generated worker and its launch environment |
| `worker.log` | Worker start, stop, iteration, and scheduling events |
| `commands.jsonl` | Tool arguments, results, errors, and durations |
| `events.jsonl` | Child session, agent, turn, message, and tool events |

Directories and worker scripts use mode 0700; data files use mode 0600. Logs exceeding 10 MiB are trimmed to their last 5 MiB when the worker checks them. Reports and logs can contain private prompts, command arguments, and tool output. `PI_LOOP_DIR` and `PI_LOOP_ITERATION` are worker-managed variables for child auditing, not normal user configuration.

## Unattended execution

Children load the normal Pi tools and extensions, including Bash. They receive instructions to treat external content as untrusted and avoid external mutations unless the original task explicitly requires them. These are model instructions, not a sandbox or enforced read-only mode. Each iteration incurs separate model usage and cannot ask interactive questions.

See [extension loading](../README.md#activation).
