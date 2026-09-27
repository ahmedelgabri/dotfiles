# zh

Shell commands run by coding agents (Claude Code, Codex, pi) are kept in their own SQLite history next to `.zsh_history` instead of inside it, so they never surface in up-arrow, substring search, or inline suggestions while staying searchable from the Ctrl-R widget in `config/zsh.d/zsh/config/extras.zsh`. `zh` is the recorder and query tool for that history: the Claude and Codex hooks and the pi `agent-history` extension call `zh record`, and the widget calls `list`, `show`, and `forget`. It replaced a Bash script and keeps its subcommands, output bytes, exit codes, and SQLite schema. The schema is created with all its columns on first write; tables from before `session`, `status`, and `description` existed are not migrated, since no database with that schema is in use.

## Database

`$ZDOTDIR/.zh.db` (falling back to `$HOME` when `ZDOTDIR` is unset or empty), created with mode 0600 in WAL mode. One table holds every record; `import-atuin` reads atuin's `history` table from a separate database attached for the duration of the import.

```mermaid
erDiagram
    commands {
        INTEGER id PK "rowid, insertion order"
        INTEGER ts "Unix seconds; indexed (commands_ts)"
        TEXT agent "claude, codex, pi, ..."
        TEXT cwd "indexed (commands_cwd)"
        TEXT cmd "the command, verbatim minus NULs"
        TEXT session "hook session_id, default ''; indexed (commands_session)"
        TEXT status "ran or failed, default 'ran'"
        TEXT description "Claude's tool_input.description, default ''"
    }
    atuin_history["atuin.history (attached, read-only)"] {
        INTEGER timestamp "nanoseconds, becomes ts / 1e9"
        TEXT command "becomes cmd"
        TEXT cwd "becomes cwd"
        TEXT author "becomes agent (claude-code to claude)"
        INTEGER author_kind "2 = agent; only these are copied"
        INTEGER deleted_at "NULL rows only"
    }
    atuin_history ||..o{ commands : "import-atuin copies agent rows"
```

Every column except `id` is `NOT NULL`. `status` is `failed` only for Claude's `PostToolUseFailure` hook events; Codex and pi always record `ran`. `list` reads `commands` newest first (`ts DESC, id DESC`), deduplicated by `cmd` unless `--all`, and hides `failed` rows unless `--all`; `stats` groups every row in scope by command prefix.

## Stats over zsh history

`zh stats` counts the most used command prefixes across agent records and the interactive zsh history, printing `count\tfailed\tprefix`.

- `--source shell|agents|all` picks the history; the default is `all`. zsh history has no directory, agent, or session, so `--dir`, `--repo`, `--agent`, and `--session` apply to agent records only: given without `--source` they select `agents`, and with `--source shell` or `all` they are a usage error, so a total never mixes filtered and unfiltered entries.
- `--histfile PATH` reads another history file; the default is `${ZDOTDIR:-$HOME}/.zsh_history`. `$HISTFILE` is not used, since `zh` runs from hooks where it is unset. A missing file counts as empty.
- `--since WHEN` and `--until WHEN` limit both sources and are both inclusive at the precision given: `YYYY-MM-DD` (a whole local day), `"YYYY-MM-DD HH:MM"` (a whole local minute), or a number of hours, days, or weeks before now such as `12h`, `3d`, or `2w` (fixed 1, 24, and 168 hours). `--since 2026-09-01 --until 2026-09-30` is September. A local time skipped by a DST change is an error; one repeated by a DST change means its earlier occurrence. Entries without a timestamp are left out whenever a bound is given.

The history is read the way zsh reads it: metafied bytes are restored, continuation lines are joined before headers are recognised, and zsh's escapes for a trailing backslash and a leading colon are undone. A test has real zsh write a history file and checks every command reads back unchanged.

Shell counts are the entries zsh kept, not every execution: `HIST_IGNORE_DUPS` and its siblings drop repeats that the agent database keeps, so compare counts within a source rather than across. zsh records no exit status, so shell entries never count toward `failed`. Shell entries pass through the same credential filter as agent records before grouping; the filter is best-effort, and the prefixes `stats` prints are only as clean as it is.

## Layout

| File | Role |
| --- | --- |
| `src/main.rs` | clap definitions, dispatch, exit codes |
| `src/db.rs` | database path, creation with mode 0600, busy timeout, schema creation |
| `src/record.rs` | hook payload parsing, credential filter, insert |
| `src/query.rs` | filters, `list`, `show`, `forget`, `stats`, `import-atuin` |
| `src/repo.rs` | jj/git root resolution for `--repo` |
| `src/zsh.rs` | zsh history file reader for `stats` |
| `src/when.rs` | `--since`/`--until` parsing and local-time resolution |
| `tests/cli.rs` | integration tests that run the built binary against real SQLite |
| `tests/fixtures/` | synthetic database, atuin database, hook payloads, and the golden case list |
| `tests/golden/` | outputs the Bash implementation produced for each case |

Unit tests live next to the code in each file's `tests` module.

## Build and test

```sh
nix develop .#rust
cargo test
cargo clippy --all-targets -- -D warnings
cargo fmt --check
```

`nix build .#zh` and `nix flake check` build the package and run the same tests in the sandbox; `git` and `jujutsu` are check inputs because the `--repo` tests create repositories. Dependencies are pinned by `Cargo.lock`, which the Nix build reads directly, so there is no vendor hash to update.

## Golden tests

`tests/fixtures/cases.json` lists invocations; `tests/golden/<name>.json` holds the exit code, stdout, and stderr the Bash implementation gave for each run, plus the resulting rows where a case sets `rows`. The integration test replays every case against the binary and compares stdout and the unchanged stderr messages byte for byte. Argument errors and help are not in the golden files: their wording is clap's, and `tests/cli.rs` asserts their exit codes separately.

The fixtures are synthetic. Never add real history to them.

## Differences from the Bash implementation

- Argument errors are clap's messages; exit codes are unchanged (64 for a missing or unknown subcommand and for bad `stats --words`/`--limit` values, 1 for other argument errors).
- `-h`/`--help` prints help and exits 0 at the top level and for every subcommand.
- `forget` parses its argument like any other: a command starting with `-` needs `forget -- CMD`.
- The credential filter uses Rust's `regex`: simple case folding and Unicode word boundaries, so shapes like `PAßWORD=x` or a zero-width joiner before `TOKEN=` are recorded where jq's Oniguruma dropped them.
- A non-string `cwd`, `session_id`, or `description` in a payload is recorded as empty instead of failing the record, and NUL characters are removed from every field.
- Output to a closed pipe ends quietly with exit 0.
