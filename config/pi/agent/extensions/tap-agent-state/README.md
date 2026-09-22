# tap agent state

Report Pi's activity to [tmux-agent-panel](https://github.com/ahmedelgabri/tmux-agent-panel) through `tap state`. The extension activates only when both `TMUX` and `TMUX_PANE` are set, and requires `tap` on PATH.

| Pi event | State reported |
| --- | --- |
| Session start | `idle` |
| Before an agent run | `running`, with the prompt as the pane title |
| Agent start | `running` |
| Agent settled | `idle` |
| Session shutdown | `clear` |

Every call includes `--agent pi`. Reporting errors are ignored so a missing or failing panel does not interrupt Pi. No Pi commands or tools are registered.

## Ownership

`index.ts` is managed by `tap`, as noted in its header. `tap install` can overwrite local edits, and `tap uninstall` removes the managed extension. After either command, check the extension directory: the installer may recreate a top-level `tap-agent-state.ts` alongside this directory entrypoint. Keep only one loaded copy to avoid duplicate event handlers.

See [extension loading](../README.md#activation).
