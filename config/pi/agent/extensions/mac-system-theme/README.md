# macOS system theme

Follow macOS appearance changes using the repository's [`plain-dark`](../../themes/plain-dark.json) and [`plain-light`](../../themes/plain-light.json) Pi themes. This runs automatically and adds no commands or tools.

The extension checks `defaults read -g AppleInterfaceStyle` on session start and every five seconds. A value of `Dark` selects `plain-dark`; an absent setting or failed read is treated as light mode. Theme changes are applied only when the detected appearance changes. The timer stops when the session shuts down.

Use this on macOS with both plain themes available on Pi's theme path. `defaults` avoids the AppleScript/System Events automation checks needed by the upstream example. There are no extension-specific settings or environment variables.

See [extension loading](../README.md#activation).
