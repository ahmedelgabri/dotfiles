# Jujutsu Revsets Reference

Revsets are expressions that select sets of commits. They're used with `-r`
flags in most commands.

## Basic Symbols

| Symbol   | Description                 |
| -------- | --------------------------- |
| `@`      | Current working copy        |
| `@-`     | Parent of working copy      |
| `@--`    | Grandparent of working copy |
| `root()` | Root commit of repository   |

## Operators

### Navigation

| Operator | Description    | Example                    |
| -------- | -------------- | -------------------------- |
| `REV-`   | Parent(s)      | `@-` (parent of @)         |
| `REV--`  | Grandparent(s) | `@--`                      |
| `REV+`   | Children       | `main+` (children of main) |
| `REV++`  | Grandchildren  | `main++`                   |

### Range Operators

| Operator | Description                             | Example                        |
| -------- | --------------------------------------- | ------------------------------ |
| `A..B`   | Ancestors of B excluding ancestors of A | `main..@` (commits since main) |
| `A::B`   | A to B inclusive                        | `main::@`                      |
| `..B`    | All ancestors of B                      | `..@`                          |
| `A..`    | A and all descendants                   | `main..`                       |
| `::B`    | All ancestors of B including B          | `::@`                          |
| `A::`    | A and all descendants including A       | `main::`                       |

### Set Operations

| Operator | Description            | Example             |
| -------- | ---------------------- | ------------------- |
| `A \| B` | Union                  | `main \| develop`   |
| `A & B`  | Intersection           | `mine() & recent()` |
| `A ~ B`  | Difference (A minus B) | `all() ~ hidden()`  |
| `~A`     | Complement             | `~empty()`          |

## Functions

### By Type

```bash
# All commits
all()

# Empty set
none()

# Root commit
root()

# All heads
heads()

# Visible heads
visible_heads()

# Trunk (main/master)
trunk()
```

### By Reference

```bash
# All bookmarks
bookmarks()

# Specific bookmark pattern
bookmarks(pattern)

# Remote bookmarks
remote_bookmarks()

# Tags
tags()

# Working copies (in workspaces)
working_copies()
```

### By Content

```bash
# Empty commits
empty()

# Commits with conflicts
conflict()

# Commits with merge conflicts
merges()

# Commits touching file
file(path)

# Commits touching files matching pattern
file(glob:*.rs)
```

### By Metadata

```bash
# By author
author(pattern)
author("name")
author(exact:"Full Name")

# By committer
committer(pattern)

# By description
description(pattern)
description("fix bug")

# By commit ID
commit_id(prefix)
```

### Ancestry

```bash
# Ancestors
ancestors(x)
x::

# Descendants
descendants(x)
::x

# Parents
parents(x)
x-

# Children
children(x)
x+

# Roots (commits with no parents in set)
roots(x)

# Heads (commits with no children in set)
heads(x)
```

### Conditional

```bash
# Returns x if it exists, empty otherwise
present(x)

# Returns first non-empty argument
coalesce(x, y)
```

### Filtering

```bash
# Filter by author
author("name") & A..B

# Filter by file
file("src/") & main..@

# Exclude empty
~empty() & main..@

# Only conflicts
conflict() & main..@
```

## Common Patterns

### Recent Work

```bash
# Commits I'm working on
jj log -r '@::'

# Commits since main
jj log -r 'main..@'

# Last 10 commits
jj log -r '@' -n 10
```

### By Author

```bash
# My commits
jj log -r 'author("myname")'

# Someone else's commits
jj log -r 'author("colleague")'

# My commits since main
jj log -r 'author("myname") & main..@'
```

### By File

```bash
# Commits that touched a file
jj log -r 'file("src/main.rs")'

# Commits in a directory
jj log -r 'file("src/")'

# Commits matching glob
jj log -r 'file(glob:*.md)'
```

### Branch Operations

```bash
# All commits on a bookmark
jj log -r 'trunk()::feature'

# Commits unique to feature
jj log -r 'trunk()..feature'

# Common ancestor
jj log -r 'heads(::main & ::feature)'

# Commits on multiple bookmarks
jj log -r 'bookmarks()'
```

### Finding Issues

```bash
# Commits with conflicts
jj log -r 'conflict()'

# Empty commits
jj log -r 'empty()'

# Merge commits
jj log -r 'merges()'
```

### History Inspection

```bash
# All ancestors of HEAD
jj log -r '::@'

# All descendants of main
jj log -r 'main::'

# Commits between two points
jj log -r 'A::B'
```

## Examples with Commands

### Rebase

```bash
# Rebase current change onto main
jj rebase -d main

# Rebase range onto target
jj rebase -r 'feature..@' -d develop

# Rebase branch onto trunk
jj rebase -b feature -d trunk()
```

### Log

```bash
# Default (relevant commits)
jj log

# All commits
jj log -r 'all()'

# Commits since branching
jj log -r 'trunk()..@'

# Specific revision
jj log -r @-
```

### Diff

```bash
# Current change
jj diff

# Specific revision
jj diff -r @-

# Range of changes
jj diff --from main --to @
```

### Show

```bash
# Working copy
jj show @

# Parent
jj show @-

# By change ID
jj show kkmpptxz
```

### Squash

```bash
# Into parent
jj squash

# Into specific revision
jj squash --into REV

# From specific revision
jj squash --from REV
```

## Aliases

Define custom revset aliases in config:

```toml
[revset-aliases]
'mine' = 'author("myemail@example.com")'
'wip' = 'description("WIP")'
'recent' = '@---::'
'feature' = 'trunk()..@'
```

Then use them:

```bash
jj log -r 'mine'
jj log -r 'wip & feature'
```

## Tips

1. **Use `present()`** for optional revisions that might not exist:

   ```bash
   jj log -r 'present(feature) | @'
   ```

1. **Combine with templates** for custom output:

   ```bash
   jj log -r 'main..@' -T 'change_id ++ " " ++ description.first_line()'
   ```

1. **Debug revsets** by checking what they select:

   ```bash
   jj log -r 'YOUR_REVSET'
   ```

1. **Quote complex revsets** in shell:
   ```bash
   jj log -r 'author("name") & file("path")'
   ```
