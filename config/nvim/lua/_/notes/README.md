# Notes setup

This directory contains the Neovim-side notes integration for the dotfiles repository. The setup keeps `zk` as the source of truth for note creation, uses `markdown_oxide` for Markdown/wiki-link LSP behavior, and uses `qmd` plus `zk` indexes for search and agent access.

## Goals

- Create notes consistently from the CLI and Neovim.
- Keep note files compatible with the Obsidian desktop app by using plain Markdown, YAML frontmatter, and Obsidian-style wiki links.
- Let `markdown_oxide` handle workspace-aware Markdown LSP features such as hover, definitions, diagnostics, and missing-link actions.
- Keep frontmatter fallback behavior independent of Obsidian.nvim.
- Keep indexing automatic for changes made by CLI commands, Neovim, Obsidian, `markdown_oxide`, or AI agents.

## Files

| File | Purpose |
| --- | --- |
| `init.lua` | Defines Neovim commands such as `:Note`, `:N`, `:NoteWork`, and `:NoteFrontmatter`. It calls `zk-nvim` for note creation and then normalizes frontmatter. |
| `frontmatter.lua` | Shared frontmatter normalization logic used by Neovim commands and the external indexer. |
| `index.lua` | Shared indexing implementation. It normalizes empty notes, runs `zk index`, and runs `qmd update`. |
| `cli.lua` | Headless Neovim entrypoint for running `index.lua` from outside Neovim with `nvim --headless --clean -u NONE -l`. |
| `README.md` | This document. |

Related files outside this directory:

| File | Purpose |
| --- | --- |
| `config/nvim/plugin/markdown.lua` | Loads Markdown plugins, configures `zk-nvim` with its LSP disabled, and calls `require('_.notes').setup()`. |
| `config/nvim/plugin/lsp.lua` | Enables `markdown_oxide` as the Markdown LSP and makes navic prefer it for Markdown symbols. |
| `config/zk/config.toml` | Owns CLI note creation aliases, filename templates, group rules, and default templates. |
| `config/zk/templates/` | Owns the actual note content templates used by `zk` for CLI and Neovim-created notes. |
| `config/zsh.d/zsh/bin/notes-index` | Small shell wrapper that launches `cli.lua` with headless Neovim. |
| `nix/parts/modules/shared/zk.nix` | Installs `zk` and `watchexec`, and defines the macOS launchd watcher that runs the headless indexer. |
| `nix/parts/modules/shared/ai.nix` | Installs `qmd`, which provides indexed search/querying for humans and agents. |
| `nix/parts/modules/shared/vim.nix` | Installs `markdown-oxide` and Neovim support tooling. |

## Creation model

`zk` is the only source of truth for creating intentional notes. This means filename generation, template expansion, group-specific behavior, and default frontmatter all come from `config/zk/config.toml` and `config/zk/templates/`.

The Neovim commands call `zk-nvim`'s API, which delegates to `zk`. They do not duplicate template rendering in Lua. Lua only decides which `zk` options to pass and then normalizes frontmatter after the file exists.

Prefer `:Note`/`:N` over the generic `:ZkNew` command for interactive note creation. `:ZkNew` remains available from `zk-nvim`, but `:Note` adds this repository's target parsing, command completion, and frontmatter normalization while still delegating note creation to `zk`.

The CLI aliases in `config/zk/config.toml` remain normal `zk` aliases, for example `zk p`, `zk w`, and `zk j`. They intentionally do not call a wrapper, because indexing is handled separately by the watcher and shared indexer.

## Neovim commands

### `:Note` and `:N`

`:Note` is the real command. `:N` is a command-line abbreviation because `:N` is already a built-in Ex command.

Examples:

```vim
:Note My root note
:N My root note
:Note work Planning note
:N personal Private note
:Note til Something I learned
:Note { dir = 'work', template = 'system-design.md', title = 'Queues' }
```

Default behavior creates a note at the root of `$NOTES_DIR`:

```vim
:N My root note
```

If the first argument is a known alias or an existing top-level subdirectory, that target is used and the rest of the command becomes the title:

```vim
:N work Team design note
:N projects Side project note
```

First-argument completion includes both configured aliases and top-level subdirectories under `$NOTES_DIR`. Hidden directories and `assets` are excluded from completion.

Bang form creates the note without opening it:

```vim
:N! Inbox note
```

### Convenience commands

These commands are thin wrappers around `:Note` aliases:

```vim
:NoteWork <title>
:NotePersonal <title>
:NoteTil <title>
:NoteJournal
:NoteRfc <title>
```

They exist for muscle memory and discoverability; the flexible `:Note`/`:N` command is the preferred base command.

### `:NoteFrontmatter`

`:NoteFrontmatter` normalizes frontmatter in the current buffer without writing the file.

`:NoteFrontmatter!` normalizes frontmatter and writes the file.

This command is useful for existing notes, notes created by tools outside the normal `zk` flow, or manual cleanup.

## Frontmatter normalization

Frontmatter normalization is implemented in `frontmatter.lua` and is deliberately independent of Obsidian.nvim.

Normalization guarantees these fields:

- `id`
- `title`
- `aliases`

The normalizer preserves other existing frontmatter fields. It also sorts known keys in this order when it rewrites frontmatter:

```text
id, title, date, aliases, tags, then all other keys in their existing order
```

### `id` fallback order

`id` is derived in this order:

1. Existing valid `id`.
2. Timestamp/date prefix in the filename.
3. Existing `date` field.
4. Current timestamp as `YYYYMMDDHHMM`.

Supported date inputs include:

```text
YYYYMMDDHHMM
YYYYMMDD
YYYY-MM-DDTHH:MM
YYYY-MM-DD HH:MM
YYYY-MM-DD
```

A date-only input falls back to midnight, so `2024-01-02` becomes `202401020000`.

### `title` fallback order

`title` is derived in this order:

1. Existing `title` field.
2. First level-one Markdown heading.
3. Filename stem with a leading timestamp/date prefix removed.

Examples:

```text
202606141200 My Note.md -> My Note
2024-01-02 My Note.md -> My Note
Plain Note.md -> Plain Note
```

### `aliases` fallback behavior

The normalizer parses existing inline or list-style aliases, then adds the normalized title as an alias if it is missing.

Examples:

```yaml
aliases: ['Existing']
```

```yaml
aliases:
  - Existing
```

Both forms are read. The rewritten form is inline:

```yaml
aliases: ['Existing', 'Title']
```

## When frontmatter normalization runs

Frontmatter normalization runs in these places:

1. After creating a note through `:Note`, `:N`, or one of the convenience commands.
2. When an empty Markdown file under `$NOTES_DIR` is opened or created in Neovim.
3. When `notes-index` runs, for empty Markdown files under `$NOTES_DIR`.
4. Manually via `:NoteFrontmatter`.

The empty-file paths are important for `markdown_oxide`: if its missing-link code action creates an empty Markdown file, opening that file in Neovim or letting the watcher index it will add fallback frontmatter.

## Indexing model

Indexing is centralized in `index.lua` and run externally through headless Neovim. The shell script `notes-index` only sets a reliable PATH and launches Lua:

```sh
nvim --headless --clean -u NONE -l ~/.dotfiles/config/nvim/lua/_/notes/cli.lua -- --quiet
```

The indexer does three things:

1. Normalize empty Markdown notes under `$NOTES_DIR`.
2. Run `zk index --quiet --notebook-dir "$NOTES_DIR"`.
3. Run `qmd update` unless `--no-qmd` is passed.

`qmd embed` is not run by the change-triggered indexer because it is heavier than metadata/index refreshes. Run it explicitly with:

```sh
notes-index --embed
```

The macOS setup also runs `notes-index --embed` periodically; see [Automatic embeddings](#automatic-embeddings).

The indexer uses a lock directory under `$XDG_CACHE_HOME/notes-index.lock` to avoid overlapping runs.

## Automatic indexing

On macOS, `nix/parts/modules/shared/zk.nix` defines a launchd user agent named `notes-index`.

That agent runs `watchexec` over `$HOME/Sync/notes` and watches Markdown file changes. After a debounce window it runs the headless Neovim indexer with `--quiet`.

This means changes made by any of these sources are eventually indexed:

- CLI `zk` aliases.
- Neovim `:Note` commands.
- Regular Neovim edits.
- Obsidian app edits.
- `markdown_oxide` missing-link file creation.
- AI agents writing Markdown files.

## Automatic embeddings

On macOS, `nix/parts/modules/shared/zk.nix` also defines a launchd user agent named `notes-embed`.

That agent runs the same headless Neovim indexer with `--quiet --embed` every hour. This keeps vector embeddings reasonably fresh without making every file save pay the embedding cost.

`notes-index` and `notes-embed` share the same lock directory, so the hourly embedding job will skip if a normal indexing run is already active, and normal indexing will skip if an embedding run is active. This avoids concurrent writes to the `zk` and `qmd` indexes.

## LSP responsibilities

`markdown_oxide` is the Markdown LSP. It owns workspace-aware Markdown behavior such as:

- wiki-link resolution
- hover
- jump to document
- diagnostics for unresolved links
- code actions for missing linked files

`zk-nvim` is still installed, but its LSP auto-attach is disabled. It is used as a command/API layer for `zk` note creation and note pickers, not as the active Markdown LSP.

Obsidian.nvim is intentionally not used. Obsidian app compatibility comes from the file format: plain Markdown, YAML frontmatter, and wiki links.

## CLI behavior

CLI note creation remains owned by `zk` and `config/zk/config.toml`.

Examples:

```sh
zk p 'Personal note'
zk w 'Work note'
zk j
zk til 'Something I learned'
```

Indexing is not embedded into those aliases. Instead, the filesystem watcher and `notes-index` handle indexing for all editors and tools uniformly.

Manual indexing:

```sh
notes-index
notes-index --quiet
notes-index --no-qmd
notes-index --embed
```

## Troubleshooting

### `:N` does not appear as a normal user command

`:N` is an abbreviation for `:Note` because `:N` is already a built-in Ex command. Use `:Note` if you want to bypass abbreviation behavior.

### A new note was created in the wrong directory

`:Note` treats the first word as a target only if it is a configured alias or an existing top-level subdirectory under `$NOTES_DIR`. Otherwise the entire command is treated as the title and the note is created at the root.

### Frontmatter was not added to a file created by another tool

Open the file in Neovim or run:

```sh
notes-index
```

You can also run `:NoteFrontmatter!` in the buffer.

### `qmd update` is slow or locked

`notes-index --no-qmd` updates only the `zk` index and empty-note frontmatter. Use this for quick manual recovery. The default watcher still attempts `qmd update` so agent search stays fresh.

### `qmd` vector results are stale

Run:

```sh
notes-index --embed
```

The change-triggered indexer updates the document index but does not refresh embeddings. The hourly `notes-embed` launchd job should catch up automatically, and `notes-index --embed` forces a manual refresh.
