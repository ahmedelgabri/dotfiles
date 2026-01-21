---
name: jujutsu
description: |
  This skill should be used when the user mentions Jujutsu version control, "jj" commands, working with jj repositories, or asks about Git to Jujutsu equivalents. Triggers on keywords like "jujutsu", "jj", "jj-vcs", "jj repo", "jj commit", "jj log", "jj new", "jj squash", "jj rebase", "jj bookmark", or questions about Jujutsu workflows and concepts.
version: 1.0.0
---

# Jujutsu (jj) Version Control Skill

This skill enables working with Jujutsu, a Git-compatible version control system
with a fundamentally different model. Jujutsu treats the working copy as a
commit, has no staging area, and uses change IDs for stable references across
rewrites.

## Core Concepts

### Working Copy as a Commit

Unlike Git, the working copy IS a commit. Changes are automatically snapshotted
when running `jj` commands - no explicit `add` or staging required.

### Change IDs vs Commit IDs

Every commit has two identifiers:

- **Change ID**: Stable across rewrites (e.g., `kkmpptxz`)
- **Commit ID**: Hash-based, changes on rewrite (e.g., `abc123def`)

Use change IDs for references that survive rebases.

### Revsets

Revsets are expressions to select commits:

- `@` - Working copy commit
- `@-` - Parent of working copy
- `root()` - Repository root
- `bookmarks()` - All bookmarked commits
- `foo..bar` - Commits from foo to bar (exclusive)
- `foo::bar` - Commits from foo to bar (inclusive)
- `A | B` - Union
- `A & B` - Intersection
- `~A` - Complement

### Bookmarks (not Branches)

Bookmarks are named pointers that map to Git branches. They move automatically
when commits are rewritten.

## Quick Reference

| Git Command                 | Jujutsu Equivalent        | Notes                            |
| --------------------------- | ------------------------- | -------------------------------- |
| `git init`                  | `jj git init`             | Use `--colocate` for Git interop |
| `git clone URL`             | `jj git clone URL`        | Git repos only                   |
| `git status`                | `jj st`                   | Shows working copy diff          |
| `git diff`                  | `jj diff`                 | Diff of working copy             |
| `git diff --staged`         | N/A                       | No staging area                  |
| `git add && git commit`     | `jj commit`               | Auto-includes all changes        |
| `git commit --amend`        | `jj squash`               | Squash into parent               |
| `git log --oneline --graph` | `jj log`                  | Visual commit graph              |
| `git show COMMIT`           | `jj show REV`             | Show revision details            |
| `git checkout -b NAME`      | `jj new`                  | Start new change                 |
| `git switch BRANCH`         | `jj edit BOOKMARK`        | Edit existing change             |
| `git reset --hard`          | `jj abandon`              | Discard working copy             |
| `git stash`                 | `jj new`                  | Just start new change            |
| `git rebase B A`            | `jj rebase -b A -d B`     | Rebase A onto B                  |
| `git cherry-pick`           | `jj duplicate`            | Copy commits                     |
| `git merge`                 | `jj new A B`              | Creates merge commit             |
| `git fetch`                 | `jj git fetch`            | Fetch from remote                |
| `git push`                  | `jj git push`             | Push bookmarks                   |
| `git branch NAME`           | `jj bookmark create NAME` | Create bookmark                  |

## Common Workflows

### Starting Work

```bash
# Clone a repo
jj git clone https://github.com/owner/repo

# Or init in existing directory
jj git init --colocate

# Create new change from main
jj new main

# Work on files (no add needed)
# Edit files...

# Describe the change
jj describe -m "feat: add new feature"

# Finish and start next change
jj new
```

### Viewing State

```bash
# Show log with graph
jj log

# Show working copy diff
jj diff

# Show specific revision
jj show @-

# Status of working copy
jj st

# Show file at revision
jj file show path/to/file -r REV
```

### Modifying History

```bash
# Squash working copy into parent
jj squash

# Squash specific change into parent
jj squash -r CHANGE

# Interactive squash (select hunks)
jj squash -i

# Split a commit
jj split

# Edit a commit message
jj describe -r REV -m "new message"

# Edit an older commit
jj edit CHANGE
# Make changes...
jj new # Return to tip
```

### Rebasing

```bash
# Rebase current change onto main
jj rebase -d main

# Rebase branch onto main
jj rebase -b BRANCH -d main

# Rebase revision and descendants
jj rebase -r REV -d DEST

# Rebase source and descendants
jj rebase -s SOURCE -d DEST
```

### Bookmarks and Remotes

```bash
# Create bookmark at current change
jj bookmark create NAME

# Create bookmark at specific revision
jj bookmark create NAME -r REV

# Move bookmark
jj bookmark move NAME -r REV

# List bookmarks
jj bookmark list

# Track remote bookmark
jj bookmark track NAME@origin

# Push bookmark to remote
jj git push --bookmark NAME

# Push all bookmarks
jj git push --all

# Fetch from remote
jj git fetch
```

### Working with GitHub

```bash
# Create PR branch
jj new main
# Work...
jj describe -m "feat: my feature"
jj bookmark create my-feature
jj git push --bookmark my-feature

# Update PR after review
jj edit my-feature
# Make changes...
jj git push --bookmark my-feature

# After merge, clean up
jj git fetch
jj bookmark delete my-feature
```

### Conflict Resolution

Conflicts in Jujutsu don't block rebases - they're recorded in commits.

```bash
# Check for conflicts
jj log # Conflicted commits shown with marker

# Resolve conflicts
jj new CONFLICTED_CHANGE
# Edit conflict markers in files
jj squash # Squash resolution into conflicted change

# Or use resolve command
jj resolve
```

### Undo Operations

```bash
# View operation log
jj op log

# Undo last operation
jj undo

# Restore to specific operation
jj op restore OP_ID
```

## Key Differences from Git

1. **No staging area**: All file changes automatically included
2. **Working copy is a commit**: Always have a "draft" commit
3. **Conflicts don't block**: Rebases complete, conflicts recorded
4. **Change IDs**: Stable references across history rewrites
5. **Operation log**: Full undo capability for any operation
6. **Automatic snapshot**: No risk of losing uncommitted work

## Colocated vs Non-colocated

**Colocated** (`jj git init --colocate`):

- `.git` and `.jj` in same directory
- Can use Git tools alongside jj
- Git sees jj commits

**Non-colocated** (`jj git init`):

- Only `.jj` directory
- Pure jj workflow
- Use `jj git export` to sync to Git

## Additional Resources

### Reference Files

For detailed command reference and advanced workflows:

- **`references/git-command-table.md`** - Complete Git to Jujutsu command
  mapping
- **`references/revsets.md`** - Revset syntax and examples

### External Documentation

- Official docs: https://docs.jj-vcs.dev/latest/
- Tutorial: https://docs.jj-vcs.dev/latest/tutorial/
- GitHub workflow: https://docs.jj-vcs.dev/latest/github/
