# Claude statusline

`statusline.sh` reads Claude Code's session JSON from stdin. `config/claude/settings.json` runs it through `~/.claude/scripts/statusline.sh`. It requires Bash, jq, and Git; jj repositories also need jj and the shared `prompt_revs()` and `prompt_fields()` aliases from `config/jj/config.toml`.

## Rendering and input handling

The statusline shows the home-relative directory path, VCS state when available, model, lines added and removed, elapsed time, estimated cost, and context usage. Paths outside `$HOME` remain absolute. Numeric formatting uses one jq invocation. Dynamic text is printed literally, without interpreting backslash escapes.

Missing metrics default to zero, the context capacity defaults to 200,000 tokens, and the model defaults to `Claude`. Missing directory data displays `?` without querying the current shell's repository. Empty, malformed, multiple, or non-object JSON inputs fail before rendering, as do invalid numeric values and control characters in text fields. Failure produces no stdout, exits with status 1, and writes `statusline: invalid session data` to stderr.

The context bar has 15 cells and cannot overflow. The percentage still shows actual usage above 100%. It counts input tokens plus cache creation and cache read tokens, excluding output tokens, matching Claude's documented formula.

Git displays the branch or a seven-character commit ID for detached HEAD, `*` for staged, unstaged, or untracked changes, a red `✗` for conflicts, and `↑N`/`↓N` for divergence from the configured upstream. Counts use local refs only; the script never fetches. `--no-optional-locks` prevents status checks from refreshing the index on disk. Unborn branches and linked worktrees are supported.

jj is queried before Git so colocated repositories keep their jj display. `--ignore-working-copy` avoids snapshotting or racing other jj commands. The dirty marker reflects the last jj snapshot, not unrecorded filesystem edits.

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
