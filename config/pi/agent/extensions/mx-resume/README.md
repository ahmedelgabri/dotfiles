# Resume after a Rex restart

On each `session_start` (startup, `/new`, `/resume`, `/fork`), write `cd -- <cwd> && pi --session-id <session id>` to `$_MX_RESUME_FILE`. The zsh in a Rex pane exports that path. After a Rex server restart, the pane's new shell puts the line on the prompt instead of the command that started pi, which would open a new session. See the restore paragraph in [`nix/pkgs/mx/README.md`](../../../../../nix/pkgs/mx/README.md).

The extension does nothing outside a Rex pane, with `--no-session`, or when the pane's shell is not pi's parent. Pi processes that tools or other agents start, such as `/loop` runs, inherit the variable but must not take over the pane. The resume line keeps no other flags.

The Claude Code and Codex side is [`config/claude/hooks/mx-resume.sh`](../../../../claude/hooks/README.md#mx-resumesh).
