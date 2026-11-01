# SketchyBar

A [SketchyBar](https://github.com/FelixKratz/SketchyBar) config that draws the tmux status bar over the macOS menu bar, plus the coding agents running in Rex.

[nix/parts/modules/darwin/sketchybar.nix](../../nix/parts/modules/darwin/sketchybar.nix) installs it on every Mac host: nix-darwin's `services.sketchybar` starts it at login and restarts it if it quits, and Home Manager links `~/.config/sketchybar` to this folder out of the store, so edits apply on `sketchybar --reload` without a rebuild. The darwin defaults already auto-hide the macOS menu bar it covers.

## Layout

| Side  | Items                                                                                                                                |
| ----- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Left  | Front app, then one item per coding agent in any Rex session, named after its Rex tab (or the agent's directory for an untitled tab) |
| Right | npm and GitHub incidents, weather, battery, Wi-Fi, next prayer, Cairo time, and date, separated by `⦁` like tmux's `status-right`    |

Agent glyphs match tmux's `window-status-format`: a cyan spinner while working, yellow `?` when done, and red `▲` when blocked or failed. Idle agents show no glyph. The left items use the same `⦁` separators as the right side, built from the shared `SEPARATOR` properties in `segments.sh`.

## Files

| File           | Role                                                                                                                                          |
| -------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `sketchybarrc` | Bar, items, and the two background helpers                                                                                                    |
| `segments.sh`  | Shared library: PATH, the plain-dark palette, the tmux-markup parser, the right-side segment commands, and the helpers' single-instance guard |
| `segment.sh`   | Plugin for each right-side segment and its separator                                                                                          |
| `front_app.sh` | Plugin for the front app name                                                                                                                 |
| `agents.sh`    | Plugin that adds, updates, orders, and removes the `agent.*` items                                                                            |
| `rex-watch.sh` | Helper that follows `rex events --all` and triggers `rex_agents_changed` on every agent status change                                         |
| `spinner.sh`   | Helper that animates working agents, because `update_freq` can't go below one second                                                          |

## How it works

- The right-side segments run the tmux scripts in [config/tmux/scripts/](../tmux/scripts/), strip their `#[fg=…]` markup, and keep the first colour, so incident and low-battery colours survive.
- Agents come straight from Rex, not from `tap`: Rex keeps the status that programs report with OSC 7501, and `agents.sh` reads it with `rex block call … program_status`. Claude Code reports it; other agents count only if they do too.
- `segments.sh` exports `REX_AUTOSTART=0`, so the bar never starts a Rex server.

## Gotchas

- Use `PragmataPro Liga`, not `PragmataPro Mono Liga`: the Mono faces shrink Nerd Font icons to one cell. macOS has no system-wide Nerd Font, and PragmataPro lacks U+F0A77, the location icon in front of the prayer time.
- `next-prayer` prints tmux markup only when `$TMUX` is set and ANSI escapes otherwise, so the prayer segment runs it with `TMUX=1`.
- launchd's PATH lacks the Nix profiles, `/usr/sbin` (for `networksetup`), and Rex's app bundle, so `segments.sh` sets PATH itself.
- macOS 27 breaks SketchyBar's `alias` items ([FelixKratz/SketchyBar#849](https://github.com/FelixKratz/SketchyBar/issues/849)), so other apps' menu bar items can't be mirrored.
