# Resume after a Rex restart

On each `session_start` (startup, `/new`, `/resume`, `/fork`), report `pi --session-id <session id>` and the session's directory to the terminal with [`resume-report`](../../../../zsh.d/zsh/bin/resume-report), using the [Program Resume Protocol](https://www.superlogical.com/rex/docs/build/program-resume). After a Rex server restart, Rex starts that command in the pane again. The `resume.trust.pi` rule in [`config/rex/init.lua`](../../../../rex/init.lua) is what lets Rex trust it, because Rex ships no rule for pi.

The extension does nothing without `OSC7577_TOKEN`, which Rex gives a pane's shell, or with `--no-session`. It removes the token from pi's environment at load, so pi processes that tools or other agents start, such as `/loop` runs, do not take over the pane. The resume command keeps no other flags.

Rex's own hook does this for Claude Code. The Codex side is [`config/claude/hooks/codex-resume.sh`](../../../../claude/hooks/README.md#codex-resumesh).
