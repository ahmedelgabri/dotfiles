# Hammerspoon configuration

This directory contains a modular Hammerspoon setup for:

- app launching and URL handling
- browser placement on the preferred display
- wake/unlock lifecycle automation
- location capture and reverse geocoding
- Wi-Fi change detection
- modal launcher keymaps
- grid-based window management
- manual runtime status snapshots from the Hammerspoon console

The config is intentionally split into small Lua modules instead of a single
large `init.lua`.

---

## Directory layout

| File                    | Purpose                                                                                                              |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `init.lua`              | Startup entry point. Configures Hammerspoon, loads modules, applies host overrides, and starts watchers.             |
| `log.lua`               | Thin wrapper around `hs.logger`.                                                                                     |
| `utils.lua`             | Shared helpers for app resolution, deep copy/merge, URL/app launching, debounce helpers, and config reload watching. |
| `layout.lua`            | Keeps the preferred browser on the largest screen.                                                                   |
| `lifecycle.lua`         | Runs delayed layout/location refresh phases after wake/unlock events.                                                |
| `location.lua`          | Captures the current location, reverse geocodes it, and writes JSON output.                                          |
| `wifi.lua`              | Watches SSID changes, sends notifications, and triggers location refresh attempts.                                   |
| `spoons.lua`            | Bootstraps SpoonInstall and configures EmmyLua, Caffeine, and URLDispatcher.                                         |
| `mappings.lua`          | Global hotkeys, modal launcher layers, and meeting mute integration.                                                 |
| `window-management.lua` | Grid-based window sizing and screen movement shortcuts.                                                              |
| `status.lua`            | Manual snapshot/logging helper for console inspection; not loaded automatically by `init.lua`.                       |
| `.luarc.jsonc`          | LuaLS configuration for Hammerspoon globals and EmmyLua annotations.                                                 |
| `.gitignore`            | Ignores generated `Spoons/`, `.DS_Store`, and some local scratch paths.                                              |

---

## Startup flow

At startup, `init.lua` does the following:

1. installs/enables the Hammerspoon IPC CLI
2. saves IPC CLI history
3. sets window animation duration to `0`
4. enables Spotlight-backed application name searches
5. determines the localized host name with `hs.host.localizedName()`
6. appends a host-specific Lua path:
   - `~/.local/share/<Host Name>/hammerspoon/?.lua`
7. resolves app bundle IDs via `utils.setup()`
8. requires the startup modules:
   - `layout`
   - `lifecycle`
   - `location`
   - `mappings`
   - `spoons`
   - `wifi`
   - `window-management`
9. attempts to load a host override module named exactly after the current host
10. runs setup/start hooks for spoons, mappings, window management, location,
    Wi-Fi, layout, and lifecycle
11. starts config watchers for:
    - `hs.configdir`
    - the host-specific extra module directory
12. shows an alert and notification with initialization timing

`status.lua` is **not** part of startup anymore. Require it manually from the
Hammerspoon console when you want to inspect runtime state.

---

## Host-specific overrides

Host overrides live outside the repo and are loaded by name.

`init.lua` builds this search path:

```text
~/.local/share/<Host Name>/hammerspoon/
```

and then tries to do the equivalent of:

```lua
require(hostName)
```

So for a machine whose localized name is `My MacBook Pro`, the override file
would be:

```text
~/.local/share/My MacBook Pro/hammerspoon/My MacBook Pro.lua
```

### Load order

The host override loads **after** the startup modules are required but
**before** their `setup()` functions are called.

That makes it a good place to customize modules that expose public config APIs,
mainly:

- `layout`
- `lifecycle`
- `spoons`

`status.lua` can also be required manually from an override if you want to use
it there, but it is otherwise not loaded automatically.

Modules that currently do **not** expose a stable runtime config API and are
mostly configured in code:

- `location`
- `mappings`
- `wifi`
- `window-management`

### Example override

```lua
local layout = require 'layout'
local lifecycle = require 'lifecycle'
local spoons = require 'spoons'

layout.setExternalBrowserPriority { 'helium', 'safari', 'firefox' }

lifecycle.configure {
	layoutDelaySeconds = 0.25,
	locationDelaySeconds = 5,
	watchedEvents = {
		sessionDidBecomeActive = true,
		screensDidUnlock = true,
		screensDidWake = false,
		systemDidWake = true,
	},
}

spoons.configureURLDispatcher {
	default_handler = 'helium',
	url_patterns = {
		{ 'https?://meet.google.com/', 'meet' },
	},
}
```

Because the config watcher also watches the host-specific directory, editing the
override triggers a reload automatically.

---

## Permissions and requirements

Some functionality depends on macOS permissions:

- **Accessibility**: required for window movement/sizing and some automation
- **Location Services**: required for `location.lua`
- **Notifications**: used by Wi-Fi, layout, and startup feedback
- **Network access**: useful for Spoon updates and reverse geocoding

If Location Services are disabled, the rest of the config still works, but
manual status snapshots will show location-related degradation/errors.

---

## Module reference

## `log.lua`

A small wrapper around:

```lua
hs.logger.new('ahmed', 'info')
```

Available helpers:

- `log.d`, `log.df`
- `log.i`
- `log.w`, `log.wf`
- `log.e`, `log.ef`
- `log.setLevel(level)`
- `log.getLevel()`
- convenience setters like `log.debug()`, `log.info()`, `log.warning()`

Example:

```lua
local log = require 'log'
log.setLevel 'debug'
```

---

## `utils.lua`

This is the shared helper module.

It does four main things:

- resolves app keys to installed bundle IDs
- provides table helpers like `deepCopy()` and `deepMerge()`
- launches apps or opens URLs via app keys
- watches config directories and coalesces reload events

### App resolution

`init.lua` calls `utils.setup()` at startup, which resolves a built-in catalog
of known apps.

Known app keys include:

- browsers: `chrome`, `firefox`, `helium`, `safari`
- terminals: `kitty`, `ghostty`
- chat/comms: `x`, `discord`, `slack`, `imessage`
- calendar/password/video: `calendar`, `1password`, `zoom`, `meet`

Most-used helpers:

- `utils.getAppBundleID(appKey)`
- `utils.resolvePreferredBrowser(priority)`
- `utils.launchOrFocus(appKey[, opts])`
- `utils.openURL(url[, appKey])`
- `utils.deepCopy(value)`
- `utils.deepMerge(base, override)`

### Merge behavior

`utils.deepMerge()` recursively merges tables, but arrays/lists are replaced
rather than merged element-by-element.

### Debounce + reload watching

`utils.startConfigWatcher()` watches one or more directories and only reloads
for changed files ending in:

- `.lua`
- `.json`
- `.jsonc`

`utils.debounce()` and `utils.cancelDebounce()` remain public and are currently
used mainly for:

- lifecycle event coalescing
- config reload coalescing

### Default browser preference

The shared fallback browser order is:

1. `firefox`
2. `safari`
3. `chrome`

Both `layout.lua` and `spoons.lua` rely on this same app-resolution layer.

---

## `layout.lua`

This module keeps the preferred browser on the **largest detected screen**.

### What it does

- enumerates all screens
- chooses the largest by full-frame area
- resolves a preferred browser from app keys or bundle IDs
- applies a one-rule Hammerspoon layout that maximizes that browser on the
  target screen
- sends a notification when the target browser moves in a multi-monitor setup
- watches screen changes and reapplies immediately

### Public functions

- `layout.setup()`
- `layout.stop()`
- `layout.switchLayout()`
- `layout.getStatus()`
- `layout.setExternalBrowserPriority(priority)`
- `layout.setExternalBrowser(browser)`

### Notes

- If no browser can be resolved, layout application is skipped.
- `priority` may be either a string or a list.
- Candidates may be app keys like `firefox` or literal bundle IDs.
- `layout.setup()` resets runtime state, but it does **not** clear the chosen
  browser priority override.

### Example

```lua
local layout = require 'layout'
layout.setExternalBrowserPriority { 'helium', 'safari', 'firefox' }
layout.switchLayout()
```

---

## `lifecycle.lua`

This module reacts to wake/unlock/session events and runs a delayed two-phase
refresh flow.

### Default settings

```lua
{
	enabled = true,
	debounceSeconds = 1,
	layoutDelaySeconds = 0.5,
	locationDelaySeconds = 3,
	watchedEvents = {
		sessionDidBecomeActive = true,
		screensDidUnlock = true,
		screensDidWake = true,
		systemDidWake = true,
	},
}
```

### What a lifecycle run does

After scheduling/debouncing, it runs:

1. a **layout** phase after `layoutDelaySeconds`
2. a **location** phase after `locationDelaySeconds`

If a phase errors or returns `false`, the overall result becomes `degraded`.

### Public functions

- `lifecycle.setup()`
- `lifecycle.stop()`
- `lifecycle.run(reason)`
- `lifecycle.schedule(reason)`
- `lifecycle.getConfig()`
- `lifecycle.getStatus()`
- `lifecycle.configure(overrides)`
- `lifecycle.setConfig(config)`
- `lifecycle.resetConfig()`

### Example

```lua
local lifecycle = require 'lifecycle'

lifecycle.configure {
	debounceSeconds = 2,
	layoutDelaySeconds = 0.25,
	locationDelaySeconds = 4,
	watchedEvents = {
		screensDidWake = false,
	},
}

lifecycle.run 'manual'
```

---

## `location.lua`

This module retrieves the current location, reverse geocodes it, and writes a
JSON payload to disk.

### Default settings

```lua
{
	outputPath = hs.fs.temporaryDirectory() .. '.location.json',
	minimumUpdateIntervalSeconds = 5,
}
```

### Startup behavior

On setup it:

1. checks Location Services availability
2. starts location tracking warmup via `hs.location.start()`
3. schedules a startup update after 1 second
4. retries up to 5 times if location is not available yet
5. stops warmup tracking once it succeeds or exhausts retries

### Runtime behavior

`location.updateLocationData(opts)`:

- records the request reason
- refuses to run if Location Services are disabled
- rate-limits non-forced updates using `minimumUpdateIntervalSeconds`
- reads the current location via `hs.location.get()`
- reverse geocodes it with `hs.location.geocoder.lookupLocation()`
- writes a JSON payload to `outputPath`
- falls back to raw location data if reverse geocoding fails

### Public functions

- `location.setup()`
- `location.stop()`
- `location.updateLocationData(opts)`
- `location.getStatus()`
- `location.writeLocationData(data)`
- `location.reverseGeocode(loc, callback)`
- `location.sanitizeLocationResult(item)`
- `location.fallbackLocationData(loc, reason)`

### Notes

- This module does **not** expose a runtime `configure()` API.
- `setup()` resets settings back to `DEFAULT_SETTINGS`.
- If you want a different output path or minimum update interval, edit the
  module.

### Manual refresh example

```lua
require('location').updateLocationData {
	force = true,
	reason = 'manual',
}
```

---

## `wifi.lua`

This module watches SSID changes.

### What it does

- tracks current and previous network names
- records when the network last changed
- sends a notification when the network changes
- triggers a direct location refresh attempt with reason `wifi`

### Public functions

- `wifi.start()`
- `wifi.stop()`
- `wifi.getStatus()`

### Notes

- The first observed network becomes the baseline and does not generate a change
  notification.
- The location refresh attempt is direct; rate limiting is handled inside
  `location.lua`.

---

## `spoons.lua`

This module manages SpoonInstall and a small set of spoons.

### Managed spoons

- `EmmyLua`
- `Caffeine`
- `URLDispatcher`

### What setup does

- loads `SpoonInstall`
- updates Spoon repos and installs/updates the managed spoons
- enables `EmmyLua`
- starts `Caffeine`
- builds and applies URLDispatcher configuration

### URLDispatcher defaults

Default behavior includes:

- Zoom meeting URLs (`https://*.zoom.us/j/`) route to `zoom`
- old `https://nixos.wiki/...` URLs redirect to `https://wiki.nixos.org/...`
- Slack redirect decoding enabled
- setting the system handler enabled
- default browser resolved from configured/default browser preference, then
  Safari as a fallback if no configured browser can be resolved

### Public functions

- `spoons.setup()`
- `spoons.updateSpoons()`
- `spoons.getStatus()`
- `spoons.getURLDispatcherConfig()`
- `spoons.getEffectiveURLDispatcherConfig()`
- `spoons.configureURLDispatcher(overrides)`
- `spoons.setURLDispatcherConfig(config)`
- `spoons.resetURLDispatcherConfig()`
- `spoons.applyURLDispatcherConfig()`

### Merge behavior

`configureURLDispatcher()` merges into the existing config.

For list-like fields:

- `url_patterns`
- `url_redir_decoders`

new items are prepended ahead of the defaults instead of replacing them.

Use `setURLDispatcherConfig()` if you want a full replacement.

### Example

```lua
require('spoons').configureURLDispatcher {
	default_handler = 'helium',
	url_patterns = {
		{ 'https?://meet.google.com/', 'meet' },
	},
}
```

---

## `mappings.lua`

This module provides global hotkeys, modal launcher layers, and meeting mute
integration.

### Default global hotkeys

| Shortcut | Action                                 |
| -------- | -------------------------------------- |
| `⌥⌘R`    | Reload Hammerspoon                     |
| `F10`    | Open the Hammerspoon console           |
| `§`      | Toggle mute in a supported meeting app |

### Hyper key

The modal layers use:

```lua
{ 'shift', 'ctrl', 'alt', 'cmd' }
```

### Layers

#### `Hyper + B` — browse

| Key   | Action                        |
| ----- | ----------------------------- |
| `m`   | Fastmail                      |
| `r`   | Reddit                        |
| `h`   | Raycast Hacker News extension |
| `f`   | Facebook                      |
| `y`   | YouTube                       |
| `x`   | X                             |
| `c`   | GitHub                        |
| `Esc` | Cancel                        |

#### `Hyper + O` — open

| Key   | Action          |
| ----- | --------------- |
| `1`   | 1Password       |
| `g`   | Google Chrome   |
| `b`   | Firefox         |
| `s`   | Slack           |
| `m`   | Messages        |
| `t`   | Ghostty         |
| `c`   | Notion Calendar |
| `z`   | Zoom            |
| `d`   | Discord         |
| `Esc` | Cancel          |

### Overlay behavior

When a modal layer opens, the config draws a small canvas overlay on the active
screen showing the available keys. The overlay disappears when the modal exits.

### Meeting mute behavior

The meeting mute hotkey:

- prefers the frontmost supported app if one matches
- otherwise falls back to any running supported meeting app
- activates that app
- waits `activationDelaySeconds` (default `0.2`)
- sends the configured keystroke
- can optionally restore the previously frontmost app

Default per-app bindings:

- `zoom` → `⌘⇧A`
- `meet` → `⌘D`

### Notes

- `setup()` resets settings to `DEFAULT_SETTINGS`.
- There is no runtime `configure()` API yet.
- Permanent changes currently belong in the module itself.

---

## `window-management.lua`

This module sets up grid-based window management with a `12x12` grid and zero
margins.

### Grid UI defaults

- font: `PragmataPro Mono`
- text size: `24`

### Shortcut behavior

Directional shortcuts cycle through related layouts for the focused window. If
you keep repeating the same chain within a short interval, the cycle wraps and
can continue on the next screen.

### Shortcuts

| Shortcut | Action                                         |
| -------- | ---------------------------------------------- |
| `⌥⌘↑`    | top half → top third → top two-thirds          |
| `⌥⌘→`    | right half → right third → right two-thirds    |
| `⌥⌘↓`    | bottom half → bottom third → bottom two-thirds |
| `⌥⌘←`    | left half → left third → left two-thirds       |
| `⌥⌘C`    | centered big → centered small                  |
| `⌥⌘F`    | fullscreen                                     |
| `⌃⌥⌘←`   | move focused window one screen west            |
| `⌃⌥⌘→`   | move focused window one screen east            |

---

## `status.lua`

This module is now a manual snapshot/logging helper only.

It is **not** required by `init.lua`, does **not** create a menubar item, does
**not** run on a timer, and does **not** auto-log anything.

Require it from the Hammerspoon console when you want a runtime snapshot.

### What it includes

A snapshot contains:

- host name
- `layout` status
- `lifecycle` status
- `location` status
- `wifi` status
- `spoons` status
- current log level
- a compact `summary` block for lifecycle/location/URLDispatcher/Wi-Fi

### Public functions

- `status.snapshot()`
- `status.log([snapshot])`
- `status.getStatus()`
- `status.clear()`

### Behavior

- `status.snapshot()` builds and caches a new snapshot.
- `status.log()` prints the provided snapshot, or the last cached snapshot, or a
  fresh snapshot if none exists.
- `status.getStatus()` returns lightweight metadata:
  - `hasSnapshot`
  - `lastLoggedAt`
- `status.clear()` clears the cached snapshot state.

### Examples

```lua
local status = require 'status'
status.log()
```

```lua
local status = require 'status'
local snapshot = status.snapshot()
print(hs.inspect.inspect(snapshot))
```

```lua
require('status').getStatus()
```

---

## Development support

### LuaLS

`.luarc.jsonc` configures LuaLS with:

- runtime: Lua 5.4
- globals: `hs`, `spoon`
- `checkThirdParty = false`
- EmmyLua annotations from:
  - `Spoons/EmmyLua.spoon/annotations`

That means editor support improves after spoons have been installed.

### Ignored/generated files

`.gitignore` ignores:

- `.DS_Store`
- `Spoons/`
- `hosts/`

except for:

- `Spoons/SpoonInstall.spoon/`

Note that the active host-override mechanism in `init.lua` uses the external
`~/.local/share/.../hammerspoon/` path, not `config/.hammerspoon/hosts/`.

---

## Useful console snippets

### Reload config

```lua
hs.reload()
```

### Show module status

```lua
require('layout').getStatus()
require('lifecycle').getStatus()
require('location').getStatus()
require('wifi').getStatus()
require('spoons').getStatus()
```

### Run lifecycle now

```lua
require('lifecycle').run 'manual'
```

### Apply layout now

```lua
require('layout').switchLayout()
```

### Refresh location now

```lua
require('location').updateLocationData { force = true, reason = 'manual' }
```

### Log a runtime snapshot

```lua
local status = require 'status'
status.log()
```

### Capture a snapshot without printing it

```lua
local status = require 'status'
status.snapshot()
```

### Change preferred browser at runtime

```lua
require('layout').setExternalBrowserPriority { 'helium', 'safari', 'firefox' }
```

---

## Troubleshooting

### The browser is not moving to the expected display

Check:

- whether the preferred browser is installed and resolvable
- `require('layout').getStatus()`
- whether Hammerspoon can see multiple screens
- whether the configured app key maps to a real bundle ID

### Location never updates

Check:

- macOS Location Services permissions for Hammerspoon
- whether `hs.location.servicesEnabled()` returns true
- the output path from `require('location').getStatus().outputPath`
- whether updates are being skipped because of the minimum update interval

### Manual status output shows an error or degraded state

Inspect:

```lua
local status = require 'status'
status.log()
require('location').getStatus()
require('lifecycle').getStatus()
```

### URLDispatcher rules are not taking effect

Check:

- that `URLDispatcher` installed successfully
- `require('spoons').getStatus()`
- whether the target app key resolves to an installed app
- whether `configureURLDispatcher()` vs `setURLDispatcherConfig()` was the right
  choice

### Hotkeys do nothing

Check:

- Hammerspoon Accessibility permissions
- whether another app intercepts the shortcut
- whether the target app behind an action is installed

---

## Design notes

A few design choices are worth calling out:

- **Event coalescing is used only where it still matters.** Config reloads and
  lifecycle wake/unlock events are still debounced, but layout reapplication and
  Wi-Fi-triggered location refreshes are direct.
- **Location updates are rate-limited, not queued.** `location.lua` uses a
  minimum update interval for ordinary refreshes instead of a separate
  scheduling layer.
- **Status inspection is manual.** `status.lua` is not part of startup, has no
  UI, and only prints snapshots when explicitly required and called.
- **Host overrides live outside the repo**, which keeps shared config separate
  from machine-specific tweaks.
- **App resolution is centralized** in `utils.lua`, so layout, launcher actions,
  meeting mute behavior, and URL dispatching all use the same app-key
  vocabulary.

---

## Quick tweak map

If you only need the common customizations, start here:

- preferred browser / screen behavior → `layout.lua`
- wake/unlock timing → `lifecycle.lua`
- URL dispatch rules → `spoons.lua`
- hotkeys / launcher actions → `mappings.lua`
- window movement behavior → `window-management.lua`
- location output path / minimum interval → `location.lua`
- runtime inspection → `status.lua`

For machine-specific behavior, prefer a host override file over editing shared
modules directly.
