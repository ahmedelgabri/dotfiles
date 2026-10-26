# tmux Configuration

Personal tmux setup managed via
[Home Manager](https://github.com/nix-community/home-manager) (Nix). Files are
symlinked from the Nix store into `~/.config/tmux/`.

Requires **tmux 3.8+** (theme detection, floating and modal panes, monitor
hooks, and auto-hiding scrollbars).

## File Structure

```
tmux/
├── README.md                          # This file
├── tmux.conf                          # Main configuration
└── scripts/
    ├── get-prayer                     # Prayer times (wrapper for next-prayer)
    ├── tmux-agent-alert               # Message when an agent stops running
    ├── tmux-battery                   # Battery segment wrapper with charging icon
    ├── tmux-statuspage                # statuspage.io incident indicator (GitHub, npm)
    └── tmux-weather                   # Weather segment (via wttr.in)
```

## Prefix

The prefix is **`C-a`** (`Ctrl-a`). The default `C-b` is unbound.

Reload the config at any time with `prefix + r`.

## Key Bindings

### Navigation

Pane navigation is
[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)-aware —
the same `C-h/j/k/l` keys work seamlessly across tmux panes and Neovim splits.
These work **without prefix** and also inside copy mode.

| Key                | Action                     |
| ------------------ | -------------------------- |
| `C-h`              | Select pane left (or Vim)  |
| `C-j`              | Select pane down (or Vim)  |
| `C-k`              | Select pane up (or Vim)    |
| `C-l`              | Select pane right (or Vim) |
| `C-\`              | Select last pane (or Vim)  |
| `Shift-Left`       | Previous window            |
| `Shift-Right`      | Next window                |
| `Ctrl-Shift-Left`  | Swap window left           |
| `Ctrl-Shift-Right` | Swap window right          |

### Windows & Panes

All require prefix unless noted.

| Key              | Action                                |
| ---------------- | ------------------------------------- |
| `prefix + c`     | New window (inherits `$PWD`)          |
| `prefix + v`     | Vertical split (left/right)           |
| `prefix + s`     | Horizontal split (top/bottom)         |
| `prefix + x`     | Kill pane (no confirmation)           |
| `prefix + b`     | Break pane to new window              |
| `prefix + C-o`   | Rotate panes                          |
| `prefix + q`     | Display pane numbers                  |
| `prefix + C-p`   | Choose tree (session/window picker)   |
| `prefix + Tab`   | Fuzzy window switcher (tmux default)  |
| `prefix + S-Tab` | Fuzzy session switcher (tmux default) |
| `prefix + C-q`   | Kill session (with confirmation)      |
| `prefix + +`     | Main-horizontal layout                |
| `prefix + =`     | Main-vertical layout                  |
| `Arrow keys`     | Resize pane by 10 cells (repeatable)  |

### Copy Mode (vi)

| Key          | Action                         |
| ------------ | ------------------------------ |
| `v`          | Begin selection                |
| `V`          | Select line                    |
| `r`          | Toggle rectangle selection     |
| `R`          | Toggle following pane output   |
| `y`          | Yank to system clipboard       |
| `Escape`     | Cancel                         |
| Mouse drag   | Copies selection to clipboard  |
| `prefix + *` | Save entire scrollback to file |

The line under the cursor is highlighted. `R` replaces tmux's default `r`
(refresh), which is taken by rectangle selection.

Clipboard uses tmux-native copy commands plus OSC 52 via `set-clipboard on`.
This keeps copy mode simple and works well in terminals like Kitty and Ghostty
without an external clipboard helper script.

### Popups

| Key                   | Action                                        |
| --------------------- | --------------------------------------------- |
| `prefix + p`          | Toggle persistent popup shell (per directory) |
| `prefix + t`          | Quick modal shell (75×75%, non-persistent)    |
| `prefix + g`          | Project/session picker (`mx --pick`)          |
| `C-Space` (no prefix) | Agent-aware pane picker (`tap pick`)          |

The persistent popup (`prefix + p`) creates a unique tmux session per working
directory (named `popup_<basename>_<hash>`) that survives closing the popup. It
opens anchored to the right side (40% width, full height). The status bar is
hidden inside popup sessions. It stays a popup because floating panes cannot be
hidden and shown again.

The quick shell (`prefix + t`) is a modal floating pane, centred in the window.
It blocks the other panes until the shell exits, and a click outside closes it.
Unlike a popup, it can be moved and resized with the mouse.

## Mouse

Mouse is fully enabled:

- Click to select pane
- Drag to enter copy mode and select text (auto-copies on release)
- Scroll wheel enters copy mode and scrolls history
- Applications that capture the mouse (e.g., vim, less) receive mouse events
  directly
- Scrollbars appear over the pane only while scrolling or hovering

## Status Bar

Position: **top**. Refresh interval: **15 seconds**.

### Layout

```
 left           center                                   right
├──────────────┬───────────┬──────────────────────────────────────────────────────────────────────────┤
│ SESSION_NAME │ ⦁ ⦁ win ⦁ │ prefix ⦁ npm ⦁ gh ⦁ weather ⦁ bat ⦁ wifi ⦁ prayer time ⦁ CAI ⦁ date/time │
└──────────────┴───────────┴──────────────────────────────────────────────────────────────────────────┘
```

| Position | Segment     | Description                                                                                                    |
| -------- | ----------- | -------------------------------------------------------------------------------------------------------------- |
| Left     | Session     | Session name — highlights blue when prefix is active                                                           |
| Center   | Window list | `⦁` per window: dark=inactive, grey=activity, red `▲`=bell. Current window shows name (yellow `` when zoomed) |
| Right    | Prefix      | Shows `^A` in blue while prefix key is held                                                                    |
|          | npm         | npm icon — only visible during incidents (5 min cache)                                                         |
|          | GitHub      | GitHub icon — only visible during incidents (5 min cache)                                                      |
|          | Weather     | Condition, temp, humidity, wind, moon phase (1 hr cache)                                                       |
|          | Battery     | Percentage with charging icon via `tmux-battery`                                                               |
|          | Wi-Fi       | Network name                                                                                                   |
|          | Prayer      | Next prayer name and time — turns red when ≤30 min remain                                                      |
|          | CAI         | Cairo time                                                                                                     |
|          | Date/time   | local day, date and time                                                                                       |

## Appearance

### Pane Borders

Borders are displayed at the **top** of each pane. In normal mode they use the
terminal's muted ANSI color. In **copy mode**, a custom indicator appears:

```
  -- COPY --                                    (N results)  [offset/total]
```

- Left: yellow `-- COPY --` marker
- Right: scroll position as offset from top, plus search result count (with `+`
  suffix if the search timed out)

The default tmux position indicator is suppressed via a `pane-mode-changed`
hook.

### Colors

The config uses `bg=terminal`, named ANSI slots, and tmux's theme colours so it
follows the terminal's dark/light palette without embedding xterm-256 grays.
tmux detects the terminal's mode and resolves `theme*` colours from the
`dark-theme-*` or `light-theme-*` options, which map them to the plain palette.
That also styles tmux's own UI (menus, popups, copy mode, scrollbars, choose
tree) in both modes. Structure (borders, separators, session name) uses
`themedarkgrey`, because ANSI `black` is near the background only in plain-dark;
dim text uses `bright black` — see the Color system section in the root README
for the slot conventions.

| Element                   | Color                |
| ------------------------- | -------------------- |
| Prefix active             | bright blue          |
| Current window            | blue                 |
| Zoomed window             | yellow               |
| Activity                  | bright black         |
| Bell                      | bright red           |
| Command line messages     | bright red           |
| Pane borders              | themedarkgrey        |
| Separators / session name | themedarkgrey        |
| Status bar dim text       | bright black         |
| Pane id / agent name      | bright black         |
| Agent running             | cyan                 |
| Agent waiting / blocked   | yellow `?` / red `▲` |

## Agent Alerts

When an agent's pane changes from `running` to `waiting` or `blocked` (tap sets
`@agent_state`), every client not showing that window gets a 5 second message
such as `? claude is waiting in dotfiles:2`. A monitor hook checks the state
once a second. Monitor hooks only watch one session, so
`tmux-agent-alert install` adds one to every session: new ones through the
`session-created` hook, existing ones on config load.

## Terminal Support

Explicit terminal features and overrides are configured for:

| Terminal | Support                                                       |
| -------- | ------------------------------------------------------------- |
| All      | RGB colour, undercurl/style                                   |
| Kitty    | Extended keys, OSC 8 hyperlinks, blinking text (`\E[5m`)      |
| Ghostty  | Extended keys, OSC 8 hyperlinks, overline (`\E[53m`/`\E[55m`) |

Escape sequence passthrough is enabled (`allow-passthrough on`) for shell
theming and Yazi image previews.

## Status Bar Scripts

All scripts are designed to be called via `#(...)` in the status bar. They
handle their own caching and error recovery.

### `tmux-weather`

Fetches weather from [wttr.in](https://wttr.in) via a `weather` CLI wrapper.
Caches to `$TMPDIR/weather.tmp` for 1 hour. Guards against missing `weather`
command and network unavailability (2s ping timeout).

### `tmux-statuspage`

One parameterized script (`tmux-statuspage <name> <statuspage-id> <icon>`) that
polls any [statuspage.io](https://www.githubstatus.com/api) status API;
`tmux.conf` invokes it for GitHub and npm. Results are cached to `$TMPDIR` for 5
minutes per service. Curl timeout is 5 seconds. Only displays an icon when
there's an active incident. Icons are passed as Unicode codepoint escapes rather
than embedded raw glyphs.

| Severity            | Color  |
| ------------------- | ------ |
| Major / Critical    | Red    |
| Minor / Maintenance | Yellow |
| None (operational)  | Hidden |

### `tmux-agent-alert`

`install [session-id...]` adds the `@agent-alert` monitor hook to the given
sessions, or to all of them. `notify <pane-id> <last-state> <state>` is what the
hook runs: it filters transitions out of `running` and sends the message with
`display-message -c` to each client whose current window is not the pane's.

### `tmux-battery`

Thin wrapper around the `battery` CLI used by the status bar. It restores the
charging icon and appends the separator only when battery output is available,
so the status bar stays clean on systems without the helper installed.

### `get-prayer`

Wrapper script that determines the prayer times source:

1. If `$TMPDIR/.location.json` exists and is valid JSON, extracts
   latitude/longitude and calls `next-prayer mawaqit` (location-aware, uses
   nearest mosque)
2. Otherwise, falls back to `next-prayer aladhan` (city-based)

When location data is available, the segment is prefixed with a location icon.
The prayer time turns **red** when ≤30 minutes remain.

With `--json` as the first argument, the script passes `-json` to `next-prayer`
and prints the day's full schedule as JSON with no icon or tmux styling; this is
the interface machine consumers like the Hammerspoon `prayer.lua` module use.

## `next-prayer` CLI

A Go CLI tool that calculates the next Islamic prayer time. The sources live in
[nix/pkgs/next-prayer/](../../nix/pkgs/next-prayer/) (only the installed binary
is needed here), built via Nix (`next-prayer.nix`) or `make build`.

### Usage

```sh
# Mawaqit (location-based, nearest mosque)
next-prayer mawaqit -latitude 52.35 -longitude 4.74

# Aladhan (city-based)
next-prayer aladhan --country nl --city amsterdam --method 3

# Full day's schedule as stable JSON (for scripts and other tools)
next-prayer aladhan -json
```

### Providers

| Provider | API                   | Auth                | Lookup                    |
| -------- | --------------------- | ------------------- | ------------------------- |
| Mawaqit  | `mawaqit.net/api/2.0` | Username + password | Lat/long → nearest mosque |
| Aladhan  | `api.aladhan.com/v1`  | None                | City + country            |

### Caching

Prayer times are cached per day to
`$TMPDIR/.prayer-<source>[_v-<parameters-hash>][_<mosque>][_<city>_<country>]_<DD-MM-YYYY>.json`,
where `<source>` is `mawaqit` or `aladhan` and the mosque part is present only
for Mawaqit. The parameter hash covers Mawaqit coordinates or the Aladhan
calculation method and tuning. A new API call is made when the source, mosque,
location, calculation settings, or date changes.

The cache file name format is private to `next-prayer`; external consumers such
as the Hammerspoon `prayer.lua` menubar module get the day's schedule through
`get-prayer --json` (which passes `-json` to `next-prayer`) instead of reading
the cache files.

### Environment Variables

| Variable            | Used by | Description        |
| ------------------- | ------- | ------------------ |
| `MAWAQIT_USERNAME`  | mawaqit | API username       |
| `MAWAQIT_PASSWORD`  | mawaqit | API password       |
| `MAWAQIT_LATITUDE`  | mawaqit | Fallback latitude  |
| `MAWAQIT_LONGITUDE` | mawaqit | Fallback longitude |

### Building

```sh
cd nix/pkgs/next-prayer

# Build binary to ./bin/next-prayer
make build

# Install to $GOBIN (default: /usr/local/bin)
make install

# Run tests
make test
```

Or via Nix (used by Home Manager):

```nix
# next-prayer.nix
buildGoModule { ... }
```

## Sessions (`mx`)

Sessions are created and attached with [`mx`](../../nix/pkgs/mx/README.md), reachable from `^G` in zsh and `prefix + g` inside tmux. Its README documents session definitions, shared windows, `--export`, and `--migrate`.

## Host-Specific Overrides

The config sources `$HOST_CONFIGS/tmux.conf` at the end if it exists. This
allows per-machine customization (e.g., different status bar segments, colors,
or bindings) without modifying the shared config. Host-local session definitions
live in `$HOST_CONFIGS/mx/sessions/`.

## Dependencies

| Dependency    | Purpose                     | Required   |
| ------------- | --------------------------- | ---------- |
| tmux ≥ 3.5    | `search_count`, format vars | Yes        |
| Neovim        | vim-tmux-navigator          | Optional   |
| `jq`          | JSON parsing in scripts     | Yes        |
| `curl`        | GitHub/npm status APIs      | Yes        |
| `battery`     | Battery status bar segment  | Optional   |
| `wifi`        | Wi-Fi status bar segment    | Optional   |
| `weather`     | Weather status bar segment  | Optional   |
| `next-prayer` | Prayer times                | Optional   |
| Go ≥ 1.24     | Building `next-prayer`      | Build only |
