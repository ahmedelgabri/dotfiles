# Pi configuration

Home Manager reads [`settings.json`](settings.json), adds host-specific resource paths, and copies the generated settings into `$PI_CODING_AGENT_DIR/settings.json` on activation. This repository sets `PI_CODING_AGENT_DIR` to `~/.config/pi/agent`. A rebuild replaces changes made through `/settings`; update the checked-in file for persistent preferences.

## Tools and display

- `defaultTools: ["+codemode"]` adds JavaScript tool orchestration without replacing `read`, `bash`, `edit`, `write`, or extension tools. Codemode keeps its default `on` mode, so direct calls remain available.
- `tuiMode: "fullscreen"` explicitly selects fullscreen rather than terminal-owned scrollback.
- `quietStartup: "header"` keeps the version and key hints without listing every loaded resource.
- `theme: "system"` derives colors from the terminal and follows terminal-reported appearance changes. The macOS polling extension is removed. The plain themes remain available for manual selection.

Rebuild Home Manager before starting a fresh Pi session so it removes the retired extension's symlinks and installs the settings. Verify the system theme inside your usual tmux session by changing the terminal between light and dark appearances. Automatic switching depends on the terminal and tmux reporting that change.

## Model setup remains manual

The configured OpenAI Codex provider, Astra model, thinking level, and model scope are unchanged. OpenAI authentication and model migration are user-managed. If switching to `/login openai`, update `defaultProvider`, `defaultModel`, and `enabledModels` here as well.

Jev credentials and provider selection are also user-managed. Codemode can discover configured classifiers with `models.getAvailableOfType("classifier")`; classifiers are not chat models in `/model`. Start with on-demand issue classification and inspect the labels before automating decisions. Hosted classification sends the supplied content to that provider. A recorded zero cost can mean missing catalog pricing rather than free service.
