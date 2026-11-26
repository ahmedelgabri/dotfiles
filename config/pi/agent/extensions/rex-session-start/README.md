# Rex session start

`rex skill setup` gives Claude Code and Codex a `SessionStart` hook that tells the agent it runs in a Rex terminal, with its `REX_BLOCK`, and points it at the `rex` CLI and skill. Pi has no command hooks, so setup skips it ([open feature request](https://discord.com/channels/1546797889009881158/1573184846656700426)).

This extension runs the same command, `rex __internal session-start --agent pi --feature-session-naming=false`, once per session (startup, `/new`, `/resume`, `/fork`), and adds its output as a `<rex>` section of the system prompt. The flags match the hooks in [`config/claude/settings.json`](../../../../claude/settings.json) and [`config/codex/hooks.json`](../../../../codex/hooks.json).

Outside a Rex pane the command prints nothing, and the prompt gets no section. If `rex` is missing or fails, the extension also adds nothing, like the other agents' hooks, which end in `|| true`. There are no commands or settings.

The section goes through `systemPromptOptions.sections` instead of a returned `systemPrompt`, as in [headless](../headless/README.md).

## Tests

From `config/pi/agent/extensions`, `node --test rex-session-start/rex-session-start.test.ts` starts actual pi in RPC mode against a loopback model, with the actual `rex` on `PATH`, and checks the system prompt with and without `REX_BLOCK` set.
