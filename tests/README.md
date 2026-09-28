# Dotfiles tests

Run these commands from the repository root. Offline checks also run through `nix flake check`; live tests are separate because they need network access or desktop services.

## Prayer wrapper

```sh
nix build .#checks.aarch64-darwin.get-prayer
python3 tests/get_prayer_test.py
python3 tests/live/get_prayer_test.py
```

The offline suite tests source selection and argument preservation with a substitute CLI, plus failure propagation with the real `next-prayer` executable. `NEXT_PRAYER_BIN` can select a built executable; otherwise it comes from `PATH`. Python, Bash, jq, and next-prayer are required.

The live E2E test uses both real provider APIs, discovers a mosque near Amsterdam, and checks JSON output and fallback with isolated config and cache directories. It requires `MAWAQIT_USERNAME` and `MAWAQIT_PASSWORD` in the environment. No credentials are written to fixtures or passed as command arguments.

Missing location fields must remain empty rather than shifting subsequent arguments. If both providers fail, the wrapper returns the Aladhan failure status instead of reporting success.

## Hammerspoon prayer module

```sh
nix build .#checks.aarch64-darwin.hammerspoon-prayer
lua tests/hammerspoon_prayer.lua "$PWD"
python3 tests/live/hammerspoon_prayer_test.py
```

The Lua 5.4 suite runs the real prayer and utility modules with a controlled clock and substitute Hammerspoon services. It covers prayer selection, highlighting, year rollover, stale schedules, notification deduplication and late timers, fetch cooldowns, invalid responses, location watchers, and cleanup. Expected failure logs are asserted.

The E2E test requires a running Hammerspoon app with its `hs` CLI available. It loads a separate module instance, uses the real task and calendar APIs to fetch an Aladhan schedule through `get-prayer`, and verifies the resulting status. It does not replace the active prayer module, create a menubar item, or send notifications. Its config, cache, Lua modules, and task are isolated and cleaned up.
