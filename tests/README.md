# Dotfiles tests

Run these commands from the repository root. Offline unit and integration checks
also run through `nix flake check`. `live/` contains E2E tests that use real
APIs or runtimes without mocks. Some need network access or desktop services;
others, such as doctor, run entirely locally.

## Python tooling

Use the default Nix shell to get the flake's pinned Python 3.14, Ruff, and ty
versions. A globally installed Ruff may be too old for the configuration.

```sh
nix develop
ruff check .
ruff format --check .
ty check .
```

To apply formatting, run `ruff format .`. Nix runs both Ruff checks through
`checks.<system>.ruff` and type checking through `checks.<system>.ty`.

[`pyproject.toml`](../pyproject.toml) enables Ruff `ALL`, preview rules, and
ty's `all = "error"`, strict equality semantics, and strict generic narrowing.
No repository Python files are excluded. The configuration explains the narrow
Ruff exceptions: mutually exclusive docstring rules, formatter-owned commas, no
per-file copyright-header policy, script layout, the retained upstream encoding
header, descriptive unittest names and assertions, and intentional subprocess
test harnesses. The chevron prompt glyph is explicitly allowed. A few
source-line exceptions document deliberate REPL output, external editor
execution, the standard-library `locals` parameter, and loading checked-in
definitions for unit tests. ty has no rule suppressions.

Python test helpers have explicit signatures and command-response types.
Executable and regex lookups fail before a missing result can reach a subprocess
or path constructor. Exit statuses remain asserted explicitly, including
expected failures.

## Python startup

```sh
nix build .#checks.aarch64-darwin.python-startup
python3 tests/python_startup_test.py
```

The startup suite covers terminal colors, pretty-printing and the `_` binding,
compiler state, failed-editor cleanup, real readline history, and editing
through an actual `ex` executable with temporary paths containing spaces. The
real-editor E2E uses no mocks; only the unit cases replace individual functions.
Everything runs offline in isolated homes and temporary directories. The direct
command requires Vim's `ex` on `PATH`; the Nix check supplies it.

See [`config/python/README.md`](../config/python/README.md) for startup behavior
and editor configuration.

## Prayer wrapper

```sh
nix build .#checks.aarch64-darwin.get-prayer
python3 tests/get_prayer_test.py
python3 tests/live/get_prayer_test.py
```

The offline suite tests source selection and argument preservation with a
substitute CLI, plus failure propagation with the real `next-prayer` executable.
`NEXT_PRAYER_BIN` can select a built executable; otherwise it comes from `PATH`.
Python, Bash, jq, and next-prayer are required.

The live E2E test uses both real provider APIs, discovers a mosque near
Amsterdam, and checks JSON output and fallback with isolated config and cache
directories. It requires `MAWAQIT_USERNAME` and `MAWAQIT_PASSWORD` in the
environment. No credentials are written to fixtures or passed as command
arguments.

Missing location fields must remain empty rather than shifting subsequent
arguments. If both providers fail, the wrapper returns the Aladhan failure
status instead of reporting success.

## Hammerspoon prayer module

```sh
nix build .#checks.aarch64-darwin.hammerspoon-prayer
lua tests/hammerspoon_prayer.lua "$PWD"
python3 tests/live/hammerspoon_prayer_test.py
```

The Lua 5.4 suite runs the real prayer and utility modules with a controlled
clock and substitute Hammerspoon services. It covers prayer selection,
highlighting, year rollover, stale schedules, notification deduplication and
late timers, fetch cooldowns, invalid responses, location watchers, and cleanup.
Expected failure logs are asserted.

The E2E test requires a running Hammerspoon app with its `hs` CLI available. It
loads a separate module instance, uses the real task and calendar APIs to fetch
an Aladhan schedule through `get-prayer`, and verifies the resulting status. It
does not replace the active prayer module, create a menubar item, or send
notifications. Its config, cache, Lua modules, and task are isolated and cleaned
up.

## Doctor

```sh
nix build .#checks.aarch64-darwin.doctor-tests
python3 tests/doctor_test.py
python3 tests/live/doctor_test.py
```

Unit tests cover each setup probe, Darwin and Linux account-shell lookup,
environment overrides, GPG's no-autostart flags, and reporting. Subprocess
integration tests check the complete script's exit status and verify that it
leaves an isolated home unchanged.

The E2E test uses real account tools, GnuPG, and an ephemeral SSH key generated
by `ssh-keygen`. It links the actual checkout into its temporary home, then
verifies the reported setup state, unchanged files, and absence of a GPG agent
socket. It never reads or copies your private keys or password store.

## mx

```sh
nix build .#checks.aarch64-darwin.mx
nix build .#mx && MX_BIN=$PWD/result/bin bash nix/pkgs/mx/tests/mx.sh
```

The suite lives with the package; see [nix/pkgs/mx/README.md](../nix/pkgs/mx/README.md#tests) for what it covers.

## mx in Rex

```sh
nix build .#mx && MX_BIN=$PWD/result/bin bash nix/pkgs/mx/tests/live-rex.sh
```

The suite runs the built `mx` with `MX_BACKEND=rex` against a real Rex server that it starts on a private socket. It needs the Rex app in `/Applications`, which is not in nixpkgs, so it is a live test with no Nix check. Every `rex` call goes through a wrapper that pins `-S` to the private socket, and the suite stops unless `rex whoami` reports that socket. [nix/pkgs/mx/README.md](../nix/pkgs/mx/README.md#tests) lists what it covers.

## Rex config

```sh
nix build .#checks.aarch64-darwin.rex-init
lua tests/rex_init.lua "$PWD"
bash tests/live/rex-init.sh
```

The Lua 5.1 suite (the Lua that Rex runs) loads the real
[`config/rex/init.lua`](../config/rex/init.lua) against a substitute `rex`
table. It checks the keymap, which process names make ctrl+h/j/k/l pass through
to the block (the programs tmux's `VIM_PATTERN` matches, including Nix
`-wrapped` names), that every other program and a block that is not a terminal
move Rex focus in the right direction with wrapping at the edges, that
`pane_focus_unless_zoomed` does nothing while the active window is zoomed, and
that `tab_new_next` passes the current tab's directory, places the tab after the
current one, and raises API errors.

The E2E suite starts a real Rex server on a private socket with the checkout's
`init.lua`, behind the same `-S` wrapper and `rex whoami` guard as the mx Rex suite.
It checks that new tabs open in the current tab's directory, both at the end and
between tabs after a `cd`. It then presses ctrl+h/j/k/l through `client.key`,
the path Rex.app uses, in a tab with a shell, a shell below it, and a real nvim
with two windows that loads the checkout's `config/nvim`. It covers moving
between Rex panes, keys passed to nvim, nvim handing an edge move back to Rex,
wrapping to the far side at every edge (Rex picks the far pane by position, not
by recent use), a zoomed nvim staying in place without wrapping, and a zoomed
shell unzooming like tmux's `select-pane`. Without an app, `tab_new_next` ends
with Rex's expected `client action was not delivered` error, which the suite
asserts. Whether Rex.app shows the focus change is not covered, because that
needs the app.

## jj templates

```sh
nix build .#checks.aarch64-darwin.jj-templates
bash tests/jj-templates.sh
```

The suite layers [`config/jj/config.toml`](../config/jj/config.toml) under a
test identity through `JJ_CONFIG` and renders real jj output for a temporary
repository. Commits come from the configured user, the same name with another
email, and another person. The compact log, the oneline log, the `gr`/`oneline`
aliases, and `jj show` must leave the author out only when both name and email
match, and otherwise show the name and email. `jj file annotate` shows them in a
32-character column, truncated with `…` when longer, and leaves it blank for the
configured user. `jj show` applies this to the committer too, so a commit by
someone else and reworded by the configured user still names its author. With no
configured email, an author without one still shows the `NO EMAIL` warning.

## Pi extensions

The Node unit, integration, and E2E tests for the
[diff](../config/pi/agent/extensions/diff/README.md#tests),
[simplify](../config/pi/agent/extensions/simplify/README.md#tests), and
[notify](../config/pi/agent/extensions/notify/README.md#tests) extensions are
colocated with them, not in this directory. Simplify's RPC client and
scripted-model helpers are in
[`lib/test-support.ts`](../config/pi/agent/extensions/lib/test-support.ts).
