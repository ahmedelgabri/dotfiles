# Agent command history

Shell commands run by coding agents (Claude Code, Codex, pi) are recorded in `$ZDOTDIR/.agent_history.db`, a SQLite database next to `.zsh_history`. They never enter the interactive history, so up-arrow, substring search, and inline suggestions only ever learn from commands typed by hand, while the Ctrl-R widget can still search what agents ran.

## How it works

`config/zsh.d/zsh/bin/agent-history` is the single writer and reader.

- `agent-history record <agent>` reads a Claude-Code-style hook payload on stdin and inserts one row (`ts`, `agent`, `cwd`, `cmd`) into the `commands` table. Commands matching credential patterns (assignments or flags named token, secret, password, or API key; bearer and basic authorization headers; `sshpass`; `gh auth login --with-token`; AWS, GitHub, Slack, and Stripe token shapes) are dropped. The database is created with mode 0600 in WAL mode; concurrent agents are serialised by SQLite with a five-second busy timeout. A payload without a Bash command is a no-op; a payload that is not JSON, a busy database, or an unwritable one exits 1 with a message on stderr, which the agents surface as a warning without blocking the tool. The `sqlite3` CLI comes from macOS on Darwin and from the `sqlite` package in the NixOS module.
- `agent-history list [--dir DIR]` prints NUL-separated `id\ttime\tdir\tcmd` records, newest first, for fzf. `id` is empty for agent records; the Ctrl-R widget uses the same columns for shell history, where `id` is the history event number. `--dir` matches DIR and everything under it; trailing slashes are ignored and `/` matches all records.

## Wiring

| Agent | Where | Events |
| --- | --- | --- |
| Claude Code | `config/claude/settings.json` | `PostToolUse` and `PostToolUseFailure`, matcher `Bash`, async |
| Codex | `config/codex/hooks.json` | `PostToolUse`, matcher `Bash` |
| pi | `config/pi/agent/extensions/agent-history/` | `tool_result` for the `bash` tool, which pi emits only for calls that executed |

Codex and pi only report calls that ran, whatever the exit status. Claude Code does the same through `PostToolUse` and additionally reports calls that did not run (denied, interrupted, tool error) through `PostToolUseFailure`, so its history also shows what the agent tried.

## Searching

Ctrl-R in zsh opens one fzf picker (`fzf-history-widget` in `config/zsh.d/zsh/config/extras.zsh`). It starts on the shell history; CTRL-A switches to agent records, CTRL-D to agent records recorded under the current directory, CTRL-R back to the shell, CTRL-Y copies the command, ALT-M toggles the time and directory columns, and `?` shows a preview. Both sources use the same `id\ttime\tdir\tcmd` rows. Shell rows are rendered from `fc -l` for display only and resolved from `$history[id]` on accept, because `fc -l` shows a real newline and a literal `\n` identically. Agent rows are inserted verbatim. Shell rows are written to a temp file once per invocation so the reload keys, which run outside the shell, can return to them.

## Inline suggestions

Ghost-text suggestions come from [deja](https://github.com/Giammarco-Ferranti/deja), which replaced zsh-autosuggestions and learns only from the interactive shell, never from the agent history. The Nix module sources deja's cached `~/.local/share/deja/init.zsh` only when the script embeds the current package's binary path; otherwise it regenerates the script with the pinned binary and restarts the daemon detached. Deja's own staleness check stats the baked binary path, which is an immutable store path, so it would never notice a Nix upgrade and would go inert once the old path is garbage collected. Tab stays with completion (`DEJA_CYCLE_KEY` is empty). After the first switch, run `deja import --file $ZDOTDIR/.zsh_history` and `deja daemon --restart` once so existing history is suggested.

## History

- deja replaced zsh-autosuggestions in both the NixOS and nix-darwin modules.

- The Ctrl-R widget replaced the atuin-backed fzf picker; fzf's stock history widget was not reused because it only knows one source.

- The pi extension replaced the `atuin` extension. It records on `tool_result` because pi-agent-core only emits it for calls that actually executed, so blocked calls are skipped without inspecting result text.

- Replaced `atuin hook claude-code` in the Claude and Codex hooks. Atuin tagged agent commands with an author so the Ctrl-R picker could filter them; without atuin, a dedicated file gives the same separation with plain zsh and fzf.
