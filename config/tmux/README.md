# tmux Configuration

Personal tmux setup managed via
[Home Manager](https://github.com/nix-community/home-manager) (Nix). Files are
symlinked from the Nix store into `~/.config/tmux/`.

Requires **tmux 3.5+** (currently running 3.6a).

## File Structure

```
tmux/
├── README.md                          # This file
├── tmux.conf                          # Main configuration
├── scripts/
│   ├── get-prayer                     # Prayer times (wrapper for next-prayer)
│   ├── tmux-battery                   # Battery segment wrapper with charging icon
│   ├── tmux-github-status             # GitHub incident indicator
│   ├── tmux-npm-status                # npm incident indicator
│   ├── tmux-weather                   # Weather segment (via wttr.in)
│   └── next-prayer/                   # Go CLI for prayer time calculation
│       ├── cmd/next-prayer/main.go    # CLI entrypoint
│       ├── aladhan/aladhan.go         # Aladhan API provider
│       ├── mawaqit/mawaqit.go         # Mawaqit API provider
│       ├── shared/shared.go           # Shared types and prayer logic
│       ├── go.mod
│       ├── Makefile
│       └── next-prayer.nix            # Nix build expression
└── .gitignore
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

| Key            | Action                               |
| -------------- | ------------------------------------ |
| `prefix + c`   | New window (inherits `$PWD`)         |
| `prefix + v`   | Vertical split (left/right)          |
| `prefix + s`   | Horizontal split (top/bottom)        |
| `prefix + x`   | Kill pane (no confirmation)          |
| `prefix + b`   | Break pane to new window             |
| `prefix + C-o` | Rotate panes                         |
| `prefix + q`   | Display pane numbers                 |
| `prefix + C-p` | Choose tree (session/window picker)  |
| `prefix + C-q` | Kill session (with confirmation)     |
| `prefix + +`   | Main-horizontal layout               |
| `prefix + =`   | Main-vertical layout                 |
| `Arrow keys`   | Resize pane by 10 cells (repeatable) |

### Copy Mode (vi)

| Key          | Action                         |
| ------------ | ------------------------------ |
| `v`          | Begin selection                |
| `V`          | Select line                    |
| `r`          | Toggle rectangle selection     |
| `y`          | Yank to system clipboard       |
| `Escape`     | Cancel                         |
| Mouse drag   | Copies selection to clipboard  |
| `prefix + *` | Save entire scrollback to file |

Clipboard uses tmux-native copy commands plus OSC 52 via
`set-clipboard on`. This keeps copy mode simple and works well in terminals
like Kitty and Ghostty without an external clipboard helper script.

### Popups

| Key          | Action                                        |
| ------------ | --------------------------------------------- |
| `prefix + p` | Toggle persistent popup shell (per directory) |
| `prefix + t` | Quick popup shell (75×75%, non-persistent)    |

The persistent popup (`prefix + p`) creates a unique tmux session per working
directory (named `popup_<basename>_<hash>`) that survives closing the popup. It
opens anchored to the right side (40% width, full height). The status bar is
hidden inside popup sessions.

## Mouse

Mouse is fully enabled:

- Click to select pane
- Drag to enter copy mode and select text (auto-copies on release)
- Scroll wheel enters copy mode and scrolls history
- Applications that capture the mouse (e.g., vim, less) receive mouse events
  directly

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

Borders are displayed at the **top** of each pane. In normal mode they're
invisible (same colour as background). In **copy mode**, a custom indicator
appears:

```
  -- COPY --                                    (N results)  [offset/total]
```

- Left: yellow `-- COPY --` marker
- Right: scroll position as offset from top, plus search result count (with `+`
  suffix if the search timed out)

The default tmux position indicator is suppressed via a `pane-mode-changed`
hook.

### Colors

The config uses `bg=terminal` throughout so colors inherit from the terminal
theme. Accent colors:

| Element               | Color                   |
| --------------------- | ----------------------- |
| Prefix active         | `colour012` (blue)      |
| Current window        | `colour004` (blue)      |
| Zoomed window         | yellow                  |
| Activity              | `colour243` (grey)      |
| Bell                  | bright red              |
| Command line messages | bright red              |
| Pane borders          | `colour235` (dark grey) |

## Terminal Support

Explicit overrides are configured for:

| Terminal | Override                     |
| -------- | ---------------------------- |
| All      | RGB colour, undercurl/style  |
| Kitty    | Blinking text (`\E[5m`)      |
| Ghostty  | Overline (`\E[53m`/`\E[55m`) |

Escape sequence passthrough is enabled (`allow-passthrough on`) for base16-shell
theming and yazi image previews.

## Status Bar Scripts

All scripts are designed to be called via `#(...)` in the status bar. They
handle their own caching and error recovery.

### `tmux-weather`

Fetches weather from [wttr.in](https://wttr.in) via a `weather` CLI wrapper.
Caches to `$TMPDIR/weather.tmp` for 1 hour. Guards against missing `weather`
command and network unavailability (2s ping timeout).

### `tmux-github-status` / `tmux-npm-status`

Poll the [GitHub](https://www.githubstatus.com/api) and
[npm](https://status.npmjs.org/api) StatusPage APIs. Results are cached to
`$TMPDIR` for 5 minutes. Curl timeout is 5 seconds. Only display an icon when
there's an active incident. Icons are emitted via Unicode codepoints in the
shell scripts rather than embedded raw glyphs.

| Severity            | Color  |
| ------------------- | ------ |
| Major / Critical    | Red    |
| Minor / Maintenance | Yellow |
| None (operational)  | Hidden |

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

## `next-prayer` CLI

A Go CLI tool that calculates the next Islamic prayer time. Built via Nix
(`next-prayer.nix`) or `make build`.

### Usage

```sh
# Mawaqit (location-based, nearest mosque)
next-prayer mawaqit -latitude 52.35 -longitude 4.74

# Aladhan (city-based)
next-prayer aladhan --country nl --city amsterdam --method 3
```

### Providers

| Provider | API                   | Auth                | Lookup                    |
| -------- | --------------------- | ------------------- | ------------------------- |
| Mawaqit  | `mawaqit.net/api/2.0` | Username + password | Lat/long → nearest mosque |
| Aladhan  | `api.aladhan.com/v1`  | None                | City + country            |

### Caching

Prayer times are cached per day to `$TMPDIR/.prayer-<city>_<country>_<DD-MM-YYYY>.json`; city/country come from location data for Mawaqit or config for Aladhan. A new API call is only made when the cache file for the current date/location doesn't exist.

The Hammerspoon `prayer.lua` menubar module reads the matching cache for the current location to display all prayer times, show cached Mawaqit mosque metadata, and notify at prayer time without making API calls.

### Environment Variables

| Variable            | Used by | Description        |
| ------------------- | ------- | ------------------ |
| `MAWAQIT_USERNAME`  | mawaqit | API username       |
| `MAWAQIT_PASSWORD`  | mawaqit | API password       |
| `MAWAQIT_LATITUDE`  | mawaqit | Fallback latitude  |
| `MAWAQIT_LONGITUDE` | mawaqit | Fallback longitude |

### Building

```sh
cd scripts/next-prayer

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

## Host-Specific Overrides

The config sources `$HOST_CONFIGS/tmux.conf` at the end if it exists. This
allows per-machine customization (e.g., different status bar segments, colors,
or bindings) without modifying the shared config.

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
| Go ≥ 1.21     | Building `next-prayer`      | Build only |
