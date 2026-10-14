# `/loop`

Run a recurring prompt in a background Pi process. Each iteration starts a fresh `pi --no-session -p` process as a direct child of the current Pi, with the task and, when available, the previous report. It does not inherit the owner's conversation history.

## Agent guidance

The extension exposes [pi-loop](skills/pi-loop/SKILL.md) through `resources_discover` in owner sessions. `/skill:pi-loop` loads scheduling guidance; it does not start a task. Loop runs load this extension in child mode, which records audit events, writes the run's structured result, offers the `loop_send` tool, and watches the owner.

## Start a loop

```text
/loop 30m Check CI and report failures without changing anything
/loop daily 09:00 Summarize pending reviews without posting comments
/loop every day at 9AM Summarize pending reviews without posting comments
/loop --passive 1h Collect release notes; only add them to the conversation
```

`/loop` or `/loop start` opens a schedule prompt, a multiline task editor, and a choice between reactive and passive delivery when UI is available. `--passive` before the schedule starts a passive loop. `/loop PROMPT` defaults to 30 minutes. `/loop start [SCHEDULE] PROMPT` is the explicit form, useful when the prompt begins with a subcommand name.

Intervals accept `s`, `m`, `h`, and `d`, including fractional values, between 30 seconds and 30 days. Every loop runs once as soon as you start or restart it, then follows its schedule. Daily schedules accept 12-hour or 24-hour times on the machine's local clock; after the first run, a daily loop runs at the next occurrence of its time, which can be only minutes later. There is no per-loop timezone option.

Runs do not overlap or replay a backlog of missed ticks. The scheduler checks the wall clock at least every 30 seconds, so system sleep does not add a full extra interval, and short intervals such as 45 seconds keep their own timing. Daily times that do not exist during a daylight-saving transition are skipped.

## Manage loops

| Command                          | Action                                                                          |
| -------------------------------- | ------------------------------------------------------------------------------- |
| `/loop list`                     | List all saved loops and the session that owns each one                         |
| `/loop status [ID]`              | Show schedule, run state, the last attempt, working directory, and file paths   |
| `/loop show [ID]`                | Open the latest report                                                          |
| `/loop logs [ID]`                | Open the runtime lifecycle log                                                  |
| `/loop commands [ID]`            | Open the tool-call audit log                                                    |
| `/loop events [ID]`              | Open the full event log                                                         |
| `/loop stop [ID]`                | Stop one loop of this session, retaining its files                              |
| `/loop stop all`                 | Stop all loops of this session                                                  |
| `/loop restart [ID]`             | Restart a stopped loop of this session; for another session's loop, offer a copy |
| `/loop resolve [ID]`             | Confirm that an uncertain earlier run is no longer running                      |
| `/loop send [ID] TEXT`           | Queue a message for the next run of a loop of this session                      |
| `/loop requeue [ID]`             | Queue the unconfirmed messages of failed runs again                             |
| `/loop toggle` or `/loop-toggle` | Collapse or expand the active loop panel                                        |
| `/loop help`                     | Show command syntax                                                             |

`Ctrl+Alt+L` also toggles the panel. Omit `ID` only when exactly one saved loop belongs to the current session. Explicit references can use an unambiguous ID prefix.

The panel starts collapsed and remembers its state. It marks passive loops with `◌ passive` and shows how many reports wait in the inbox for each loop. `/loop status` and `/loop list` show each loop's delivery mode. Loops created before delivery modes existed are reactive. `runs.log` retains the report history subject to log trimming.

## Reports and the inbox

Each finished run publishes one JSON file into the owner session's inbox, `inboxes/<session>/pending/` in the state directory. The child writes its own result when its agent settles; if it crashed, the owner writes a failure report with the exit code and the end of stderr. The owner then moves each report into the main conversation:

- **Reactive (the default):** the report joins the model context and the agent responds by itself. When the agent is idle, this happens at once; when it is busy, after its current run.
- **Passive (`--passive`):** the report joins the model context without starting a turn; the agent sees it with your next prompt. When the agent is busy, the report joins at the end of the current turn, which is the earliest point Pi allows during a run.
- **Toast:** a notice appears as soon as a report arrives, even while the agent is busy.

A run can also send up to three notes of at most 8 KB each before it ends, with the `loop_send` tool. Notes take the same path as reports, are never merged into a digest, and show as `✉` cards. The run's instructions say to use them only for results that cannot wait for the final report.

A report becomes a bordered card in the transcript. Its status line shows success or failure, the exit code, the duration, the time, `agent reacting` or `in context`, and `untrusted`. Cards always show the whole report; `Ctrl+O` does not change them. When several reports of one loop arrive together, for example after a long agent run, the card shows the newest report in full and a one-line digest of each earlier run. The model receives the same reports after a sentence that marks them as untrusted output of an unattended run; the card hides that sentence. Reports from before the inbox render with the same card, marked `display only`, because they never reached the model.

An inbox file is deleted only after its ID appears in a complete record of the session file on disk. Until then it stays pending, so a crash, quit, or `/reload` can delay a report but cannot lose it or deliver it twice. Sessions that Pi does not save, such as `--no-session`, never write that record, so their inbox files stay pending. Malformed files, and files whose identity does not match their name or session, move to `inboxes/<session>/rejected/` with one notice each.

"Delivered" means recorded in the session. It does not mean that the model acted on the report. Nothing here gives exactly-once execution of anything a report asks for.

## Messages for the next run

`/loop send [ID] TEXT` queues a message of at most 8 KB for a loop's next run, for example `/loop send also check PR #900`. A leading token counts as the loop ID only if it names exactly one loop; otherwise the whole text is the message for the session's only loop. The message waits in the loop's `inbox/` directory.

When the next run starts, it claims every queued message into `claimed/<iteration>/` and receives each one as an attached JSON file, with an instruction to apply it. These are next-run inputs, not a live channel to a run in progress. A run confirms its messages by finishing with a successful result; then its claim is deleted.

Any other outcome leaves the claim in place: a failed run, a missing result, a stop, or a crash. Such messages are never replayed automatically, because the failed run may already have done part of what they asked. `/loop status`, the panel, and the failed run's report card show how many messages need review. `/loop requeue ID` puts them back into `inbox/` for the next run; a requeued message can repeat a side effect that the failed run already did. The requeue moves each file with a single rename inside the loop directory, so a crash leaves each message in exactly one place. It skips the claim of a run in progress and keeps, and reports, a file that differs from an already queued copy with the same ID.

## Lifetime

A loop belongs to the session that created it and runs only inside the Pi process that has that session open:

- **Quit, `/new`, `/resume`, and `/fork`** stop the session's loops. A stopped loop stays stopped until `/loop restart` in its own session. In another session, `/loop restart ID` offers to start a copy with the same prompt, schedule, and model.
- **`/reload`** keeps running loops. A run that is in progress continues, and its report still arrives once.
- **A crash or kill of Pi** stops new runs at once. A running child checks every 2 seconds whether its parent is gone and then stops itself. The next time the session starts, an unfinished run is recovered with a failure report.

A stop sends TERM to the run. Pi's own signal handler then kills the run's tracked tool processes. If the run has not exited after 10 seconds, it gets KILL on its process group, followed by up to 5 more seconds of waiting. Quitting Pi with a stuck run can therefore take about 15 seconds. A run that survives even that shows as "still stopping", and restart is refused until it exits.

Only one Pi process controls a session's loops. It holds `inboxes/<session>/receiver.lock` in the state directory. A second Pi on the same session can list and show loops but cannot start, stop, or restart them. A crashed Pi leaves the lock behind; the warning shows its path, and you delete it by hand once the old process is gone. The lock is never taken over automatically.

When a session starts, unfinished earlier runs are checked against one full process snapshot:

- **Gone:** the run is finalized with a report that says the owner ended first.
- **Still running:** the loop shows "previous run still active". Restart works after that run stops by itself.
- **Uncertain:** the run's identity cannot be confirmed, for example because Pi crashed while it launched the run. Restart is refused. If the run is no longer running, confirm with `/loop resolve ID`.

### Termination limits

Loop runs clean up like a normal Pi session does when you quit it. That is not a guarantee for every process that a run started:

- **Forced termination:** if a run cannot execute its TERM handler (a blocked event loop, or the KILL escalation), its tool processes can survive. Pi starts each bash tool command in its own process group, and the KILL of the run's group does not reach those groups.
- **Untracked processes:** processes started by custom extensions are not tracked by Pi.
- **Deliberate detach:** a tool command can start a process in its own session or process group on purpose, for example with `setsid`, as a daemon, or with `nohup … &` in a shell with job control. Such a process outlives its finished tool and the run.
- **Crash detection** needs the child's event loop to run its 2-second check.

The owner signals only its own child and that child's process group, never other processes.

### Loops from earlier versions

Earlier versions ran each loop in a detached tmux session named `pi-loop-<ID>`. This version ignores their saved loops and does not look for those sessions. Stop any that still run by hand.

## Requirements

`pi` must be either a standalone binary or a Node/Bun script, so the owner can start it again as a direct child. tmux is not needed. The loop saves its working directory, provider, model, and thinking level at creation. Child processes must be able to resolve that model and its credentials.

## State and privacy

Storage is `${XDG_STATE_HOME:-$HOME/.local/state}/pi-loop`, overridden by `PI_LOOP_STATE_DIR`. Each loop directory contains:

| File                         | Contents                                                          |
| ---------------------------- | ----------------------------------------------------------------- |
| `config.json`, `prompt.md`   | Saved configuration and task                                      |
| `latest.md`, `runs.log`      | Latest report and accumulated reports                             |
| `state.json`                 | Status, iteration, timing, exit code, and the last attempt record |
| `run.stdout`, `run.stderr`   | Output of the current or last run                                 |
| `runtime.log`                | Run start, finish, and recovery events                            |
| `commands.jsonl`             | Tool arguments, results, errors, and durations                    |
| `events.jsonl`               | Child session, agent, turn, message, and tool events              |
| `results/<n>.json`           | The run's structured result, until the owner publishes it         |
| `results/<n>.child.json`     | The PID and start time that each run records for itself           |
| `inbox/`, `claimed/<n>/`     | Queued owner messages, and the messages each run claimed          |

The state directory also holds `inboxes/<session>/` with `pending/`, `rejected/`, and `receiver.lock`. The attempt record is written before each run starts, so a crash can never reuse an iteration number. Directories use mode 0700 and files use mode 0600. Logs exceeding 10 MiB are trimmed to their last 5 MiB. Reports and logs can contain private prompts, command arguments, and tool output. `PI_LOOP_DIR`, `PI_LOOP_ID`, `PI_LOOP_ITERATION`, `PI_LOOP_OWNER_SESSION_ID`, `PI_LOOP_PARENT_PID`, `PI_LOOP_RESULT`, and `PI_LOOP_INBOX` are set for child runs, not normal user configuration.

## Unattended execution

Children load the normal Pi tools and extensions, including Bash. They do not receive the owner's pane identity (`TMUX`, `TMUX_PANE`, `REX_SESSION`, `REX_BLOCK`), because a run has no terminal: with it, pane-aware extensions would treat your Pi pane as the run's own, for example by splitting it for worker panes or by reporting agent state for it. They receive instructions to treat external content as untrusted and avoid external mutations unless the original task explicitly requires them. These are model instructions, not a sandbox or enforced read-only mode. Each iteration incurs separate model usage and cannot ask interactive questions.

Reactive delivery, the default, adds a risk: a report can carry text from Slack, email, web pages, or tool output, and it starts a turn of the main agent, which has your full tools, possibly while you are away. The untrusted-data sentence is a model instruction, not an enforcement. Each reactive report also costs a model turn. Use `--passive` for loops whose output does not need an immediate response.

## Validation

Run the type check and the suite from `config/pi/agent/extensions` with Node.js 24 or later. The suite starts real `pi` processes against a loopback scripted model, so it needs no credentials.

```sh
tsc --noEmit -p tsconfig.json
node --test loop/loop.test.ts
```

The end-to-end suite runs by hand. It uses the real agent directory, credentials, and model, so each run costs a few model calls. It covers reactive and passive delivery, a `/loop send` message, and quitting or killing the owner during a run:

```sh
PI_E2E_MODEL=anthropic/claude-haiku-4-5 node --test loop/loop.e2e.test.ts
```

Every test signals only processes that it started or recorded, after checking their start time. No test needs tmux or Rex. The end-to-end suite uses a temporary loop state directory and gives the owner no pane identity.

See [extension loading](../README.md#activation).
