# Pi configuration

Home Manager reads [`settings.json`](settings.json), adds host-specific resource
paths, and copies the generated settings into
`$PI_CODING_AGENT_DIR/settings.json` on activation. This repository sets
`PI_CODING_AGENT_DIR` to `~/.config/pi/agent`. A rebuild replaces changes made
through `/settings`; update the checked-in file for persistent preferences.

## Tools and display

- `defaultTools: ["+codemode"]` adds JavaScript tool orchestration without
  replacing `read`, `bash`, `edit`, `write`, or extension tools. Codemode keeps
  its default `on` mode, so direct calls remain available.
- `tuiMode: "fullscreen"` explicitly selects fullscreen rather than
  terminal-owned scrollback.
- `quietStartup: "header"` keeps the version and key hints without listing every
  loaded resource.
- `theme: "system"` derives colors from the terminal and follows
  terminal-reported appearance changes. The macOS polling extension is removed.
  The plain themes remain available for manual selection.

Rebuild Home Manager before starting a fresh Pi session so it removes the
retired extension's symlinks and installs the settings. Verify the system theme
inside your usual tmux session by changing the terminal between light and dark
appearances. Automatic switching depends on the terminal and tmux reporting that
change.

## Native MCP servers

[`agent/mcp.json`](agent/mcp.json) replaces the custom `web-search` and `linear`
extensions. Home Manager's existing agent-directory tree links it into
`$PI_CODING_AGENT_DIR/mcp.json`; it contains no credentials. Both servers use
native HTTP MCP with codemode exposure, so their tools are discovered when
needed rather than all being declared on every request.

- **Exa:** `https://mcp.exa.ai/mcp`, using the hosted service's default tools
  without a configured API key. Query text is sent to Exa.
- **Linear:** `https://mcp.linear.app/mcp`, the normal endpoint with no
  read-only exposure overrides. It can expose write operations; the credential's
  permissions still determine what succeeds. Issue data is sent to Linear, and
  any data subsequently submitted to a classifier also goes to that classifier's
  provider.

Linear's Authorization header is resolved at connection time by running
`${XDG_CONFIG_HOME:-$HOME/.config}/zsh/bin/secret get linear-api-token`. The
command fails rather than emitting a bearer header when the helper fails or
returns an empty token. Pi runs credential commands with a ten-second timeout,
so unlock the keychain first if necessary. The token is not evaluated by Nix or
embedded in the store. The former extension's mutation rejection and per-request
keychain lookup are no longer present.

Keep or rotate the credential with `secret set linear-api-token`, which prompts
without putting the value in shell history. This migration does not broaden an
existing read-only key; grant the desired permissions in Linear yourself.
Because an explicit Authorization header is configured, `/mcp login linear` is
not used for this setup. After rotating the key, reconnect Linear through `/mcp`
or restart Pi.

Rebuild Home Manager to add the MCP link and remove the retired extension links,
then start a fresh session. Use `pi mcp list` to verify both connections and
`/mcp` to inspect their tools. Changes to the linked MCP file take effect after
`/reload`; changes made through `/mcp` can also modify the checked-in file.
Neither the MCP configuration nor codemode asks for approval before every write.
In particular, unattended `/loop` tasks inherit these servers and their
available permissions.

## Model setup remains manual

The configured OpenAI Codex provider, Astra model, thinking level, and model
scope are unchanged. OpenAI authentication and model migration are user-managed.
If switching to `/login openai`, update `defaultProvider`, `defaultModel`, and
`enabledModels` here as well.

Jev credentials and provider selection are also user-managed. Codemode can
discover configured classifiers with `models.getAvailableOfType("classifier")`;
classifiers are not chat models in `/model`. Start with on-demand issue
classification and inspect the labels before automating decisions. Hosted
classification sends the supplied content to that provider. A recorded zero cost
can mean missing catalog pricing rather than free service.

## Deferred experiments

- Run Jev model-routing recommendations in observation mode before switching
  models automatically. Compare decisions against real tasks, latency, total
  cost, and cache misses. A first file edit is not evidence that the hard
  reasoning is finished.
- For `/loop`, detect identical reports deterministically before adding
  classification. Show labels and uncertain results before considering
  notification suppression.
- For `/simplify`, aggregate child-reviewer usage first. Classifier-assisted
  grouping can come later; the parent must still inspect every finding against
  the code.
- Consider an explicit `/illustrate` command with a selected image provider and
  output directory for visual assets. Keep technical diagrams in Mermaid.

These are proposals, not enabled features. OpenAI migration and Jev
authentication remain user-managed.
