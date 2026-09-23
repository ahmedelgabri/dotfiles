# Claude statusline

`statusline.sh` reads Claude Code's session JSON from stdin. `config/claude/settings.json` runs it through `~/.claude/scripts/statusline.sh`. It requires Bash, jq, and Git; jj repositories also need jj and the shared `prompt_revs()` and `prompt_fields()` aliases from `config/jj/config.toml`.

## Rendering and input handling

The full statusline shows the home-relative directory path, VCS state when available, model, lines added and removed, elapsed and API time, estimated cost, and context usage. Paths outside `$HOME` remain absolute. Numeric formatting uses one jq invocation. Dynamic text is printed literally, without interpreting backslash escapes.

Missing metrics default to zero, except API time, which is omitted when absent or null. The context capacity defaults to 200,000 tokens, and the model defaults to `Claude`. Missing directory data displays `?` without querying the current shell's repository. Empty, malformed, multiple, or non-object JSON inputs fail before rendering, as do invalid numeric values and control characters in text fields. Failure produces no stdout, exits with status 1, and writes `statusline: invalid session data` to stderr.

The context bar has 15 cells in the full layout and cannot overflow. The percentage still shows actual usage above 100%. The bar and percentage turn yellow at 70% and red at 90%. Token counts use compact units, such as `84k/200k` or `3.4k/1M`. They count input tokens plus cache creation and cache read tokens, excluding output tokens, matching [Claude's documented formula](https://code.claude.com/docs/en/statusline#context-window-fields).

Elapsed time is the session's accumulated wall-clock duration. `API` is the accumulated time waiting for API responses, from `cost.total_api_duration_ms`. Both use the same duration formatter.

Git displays the branch or a seven-character commit ID for detached HEAD, `*` for staged, unstaged, or untracked changes, a red `✗` for conflicts, and `↑N`/`↓N` for divergence from the configured upstream. Counts use local refs only; the script never fetches. `--no-optional-locks` prevents status checks from refreshing the index on disk. Unborn branches and linked worktrees are supported.

jj is queried before Git so colocated repositories keep their jj display. `--ignore-working-copy` avoids snapshotting or racing other jj commands. The dirty marker reflects the last jj snapshot, not unrecorded filesystem edits.

## Compact layout

Claude sets `COLUMNS` to the current terminal width before invoking the script. Below 120 columns, the statusline uses a five-cell context bar and omits line-change counts, timing, and cost. Paths retain their last 23 characters with a leading ellipsis when longer than 24 characters. Branches, the bookmark list, and workspace names retain their first 17 characters with a trailing ellipsis when longer than 18 characters. VCS state markers, model, context percentage, and token counts remain visible.

Missing or invalid width data uses the full layout. Compact mode reduces detail rather than guaranteeing a fit at every width; very narrow terminals or long model names can still wrap. No terminal probing or cache is needed.

Full layout:

```text
~/work/project (main) | Opus +1,234 -12 in 1.1m (API 1.0s) for $0.123 | ██████░░░░░░░░░ 42% 84k/200k
```

Compact layout:

```text
~/work/project (main) | Opus | ██░░░ 42% 84k/200k
```

## Validation

Run from the repository root:

```sh
bash -n config/claude/scripts/statusline.sh
shellcheck config/claude/scripts/statusline.sh
shfmt -d config/claude/scripts/statusline.sh
```

## Change summary

- Check jq success before rendering and provide defaults for missing session fields.
- Preserve literal text, constrain the context bar, and omit empty VCS parentheses.
- Preserve directory context with home-relative paths and show Git dirty, conflict, detached HEAD, and divergence indicators.
- Add context token counts, pressure colors, and API versus elapsed duration.
- Switch automatically to compact output below 120 columns, preserving VCS state markers.
