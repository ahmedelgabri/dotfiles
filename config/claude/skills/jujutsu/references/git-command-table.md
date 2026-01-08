# Git to Jujutsu Command Reference

Complete mapping of Git commands to their Jujutsu equivalents.

## Repository Management

| Git                         | Jujutsu                        | Notes                            |
| --------------------------- | ------------------------------ | -------------------------------- |
| `git init`                  | `jj git init`                  | Add `--colocate` for Git interop |
| `git init`                  | `jj git init --no-colocate`    | Pure jj repository               |
| `git clone URL`             | `jj git clone URL`             | Only Git repos supported         |
| `git clone URL DIR`         | `jj git clone URL DIR`         | Clone to directory               |
| `git remote -v`             | `jj git remote list`           | List remotes                     |
| `git remote add NAME URL`   | `jj git remote add NAME URL`   | Add remote                       |
| `git remote remove NAME`    | `jj git remote remove NAME`    | Remove remote                    |
| `git remote rename OLD NEW` | `jj git remote rename OLD NEW` | Rename remote                    |

## Fetching and Pushing

| Git                         | Jujutsu                                            | Notes                     |
| --------------------------- | -------------------------------------------------- | ------------------------- |
| `git fetch`                 | `jj git fetch`                                     | Fetch all tracked remotes |
| `git fetch REMOTE`          | `jj git fetch --remote REMOTE`                     | Fetch specific remote     |
| `git fetch --all`           | `jj git fetch --all-remotes`                       | Fetch all remotes         |
| `git push`                  | `jj git push`                                      | Push tracked bookmarks    |
| `git push --all`            | `jj git push --all`                                | Push all bookmarks        |
| `git push REMOTE BRANCH`    | `jj git push --bookmark NAME --remote REMOTE`      | Push specific bookmark    |
| `git push -u origin BRANCH` | `jj git push --bookmark NAME`                      | Creates remote tracking   |
| `git push --force`          | `jj git push --allow-new`                          | Force push (careful)      |
| `git push --delete BRANCH`  | `jj bookmark delete NAME && jj git push --deleted` | Delete remote branch      |

## Viewing State

| Git                           | Jujutsu                    | Notes                   |
| ----------------------------- | -------------------------- | ----------------------- |
| `git status`                  | `jj st` or `jj status`     | Working copy status     |
| `git diff`                    | `jj diff`                  | Working copy diff       |
| `git diff HEAD`               | `jj diff`                  | Same - no staging area  |
| `git diff --staged`           | N/A                        | No staging area in jj   |
| `git diff --cached`           | N/A                        | No staging area in jj   |
| `git diff A B`                | `jj diff --from A --to B`  | Diff between revisions  |
| `git diff A..B`               | `jj diff --from A --to B`  | Same                    |
| `git show COMMIT`             | `jj show REV`              | Show revision           |
| `git show COMMIT:FILE`        | `jj file show FILE -r REV` | Show file at revision   |
| `git log`                     | `jj log`                   | Commit log              |
| `git log --oneline`           | `jj log`                   | Default is oneline      |
| `git log --oneline --graph`   | `jj log`                   | Default includes graph  |
| `git log -p`                  | `jj log -p`                | Log with patches        |
| `git log --all`               | `jj log -r 'all()'`        | All commits             |
| `git log -n 5`                | `jj log -n 5`              | Limit commits           |
| `git log FILE`                | `jj log FILE`              | File history            |
| `git log --follow FILE`       | `jj log FILE`              | Default follows renames |
| `git blame FILE`              | `jj file annotate FILE`    | Blame/annotate          |
| `git cat-file -p COMMIT:FILE` | `jj file show FILE -r REV` | Show file content       |

## Making Changes

| Git                            | Jujutsu                             | Notes                    |
| ------------------------------ | ----------------------------------- | ------------------------ |
| `git add FILE`                 | N/A                                 | Auto-tracked             |
| `git add -A`                   | N/A                                 | Auto-tracked             |
| `git add -p`                   | `jj split`                          | Interactive splitting    |
| `git commit`                   | `jj commit`                         | Commit working copy      |
| `git commit -m "MSG"`          | `jj commit -m "MSG"`                | Commit with message      |
| `git commit -a`                | `jj commit`                         | Default includes all     |
| `git commit --amend`           | `jj squash`                         | Amend into parent        |
| `git commit --amend -m "MSG"`  | `jj squash && jj describe -m "MSG"` | Amend + change message   |
| `git commit --amend --no-edit` | `jj squash`                         | Amend keeping message    |
| `git commit --fixup COMMIT`    | `jj squash --into REV`              | Squash into specific rev |
| `git rm FILE`                  | `rm FILE`                           | Just delete the file     |
| `git mv OLD NEW`               | `mv OLD NEW`                        | Just move the file       |

## History Modification

| Git                         | Jujutsu                                  | Notes                      |
| --------------------------- | ---------------------------------------- | -------------------------- |
| `git rebase TARGET`         | `jj rebase -d TARGET`                    | Rebase current onto target |
| `git rebase TARGET BRANCH`  | `jj rebase -b BRANCH -d TARGET`          | Rebase branch onto target  |
| `git rebase -i`             | `jj squash -i` / `jj split`              | Interactive operations     |
| `git rebase --onto NEW OLD` | `jj rebase -r OLD -d NEW`                | Move commits               |
| `git cherry-pick COMMIT`    | `jj duplicate REV`                       | Duplicate commit           |
| `git cherry-pick A..B`      | `jj duplicate A::B`                      | Duplicate range            |
| `git revert COMMIT`         | `jj backout -r REV`                      | Create reverting commit    |
| `git reset HEAD~`           | `jj squash --into @--`                   | Uncommit to grandparent    |
| `git reset --hard`          | `jj abandon`                             | Discard working copy       |
| `git reset --hard COMMIT`   | `jj edit REV`                            | Move to revision           |
| `git reset --soft HEAD~`    | `jj squash --into @-` then `jj unsquash` | Complex in jj              |

## Branching and Bookmarks

| Git                           | Jujutsu                             | Notes                     |
| ----------------------------- | ----------------------------------- | ------------------------- |
| `git branch`                  | `jj bookmark list`                  | List bookmarks            |
| `git branch -a`               | `jj bookmark list --all`            | Include remote bookmarks  |
| `git branch NAME`             | `jj bookmark create NAME`           | Create bookmark           |
| `git branch NAME COMMIT`      | `jj bookmark create NAME -r REV`    | Create at revision        |
| `git branch -d NAME`          | `jj bookmark delete NAME`           | Delete bookmark           |
| `git branch -D NAME`          | `jj bookmark delete NAME`           | Same - no protection      |
| `git branch -m OLD NEW`       | `jj bookmark rename OLD NEW`        | Rename bookmark           |
| `git checkout BRANCH`         | `jj edit BOOKMARK`                  | Edit bookmarked revision  |
| `git checkout -b NAME`        | `jj new && jj bookmark create NAME` | New bookmark + change     |
| `git switch BRANCH`           | `jj edit BOOKMARK`                  | Switch to bookmark        |
| `git switch -c NAME`          | `jj new && jj bookmark create NAME` | Create and switch         |
| `git checkout COMMIT`         | `jj new REV`                        | Start new change from rev |
| `git checkout -- FILE`        | `jj restore FILE`                   | Restore file              |
| `git checkout COMMIT -- FILE` | `jj restore --from REV FILE`        | Restore from revision     |

## Merging

| Git                         | Jujutsu                   | Notes                |
| --------------------------- | ------------------------- | -------------------- |
| `git merge BRANCH`          | `jj new @ BRANCH`         | Create merge commit  |
| `git merge --no-ff BRANCH`  | `jj new @ BRANCH`         | Always creates merge |
| `git merge --squash BRANCH` | `jj squash --from BRANCH` | Squash merge         |
| `git merge --abort`         | `jj undo`                 | Undo merge           |

## Stashing

| Git              | Jujutsu                    | Notes                       |
| ---------------- | -------------------------- | --------------------------- |
| `git stash`      | `jj new`                   | Just start new change       |
| `git stash pop`  | `jj squash --from STASHED` | Squash stashed into current |
| `git stash list` | `jj log`                   | View all changes            |
| `git stash drop` | `jj abandon REV`           | Abandon the change          |

Jujutsu doesn't need stash - just create a new change and come back later.

## Workspace (Worktrees)

| Git                        | Jujutsu                    | Notes            |
| -------------------------- | -------------------------- | ---------------- |
| `git worktree add PATH`    | `jj workspace add PATH`    | Add workspace    |
| `git worktree list`        | `jj workspace list`        | List workspaces  |
| `git worktree remove PATH` | `jj workspace forget NAME` | Remove workspace |

## Cleaning

| Git              | Jujutsu      | Notes              |
| ---------------- | ------------ | ------------------ |
| `git clean -fd`  | `jj restore` | Restore all files  |
| `git clean -fdx` | `jj restore` | Ignored files stay |

## Inspection

| Git                          | Jujutsu                            | Notes           |
| ---------------------------- | ---------------------------------- | --------------- |
| `git reflog`                 | `jj op log`                        | Operation log   |
| `git describe`               | `jj log -r @ -T 'description'`     | Get description |
| `git rev-parse HEAD`         | `jj log -r @ -T 'commit_id'`       | Get commit ID   |
| `git rev-parse --short HEAD` | `jj log -r @ -T 'short_commit_id'` | Short commit ID |

## Configuration

| Git                            | Jujutsu                          | Notes            |
| ------------------------------ | -------------------------------- | ---------------- |
| `git config KEY VALUE`         | `jj config set --user KEY VALUE` | Set user config  |
| `git config --local KEY VALUE` | `jj config set --repo KEY VALUE` | Set repo config  |
| `git config --list`            | `jj config list`                 | List config      |
| `git config KEY`               | `jj config get KEY`              | Get config value |

## Operations Without Direct Git Equivalent

### Change Description

```bash
# Add/edit commit message
jj describe -m "message"

# Edit message of specific revision
jj describe -r REV -m "message"

# Interactive message editor
jj describe
```

### Splitting Changes

```bash
# Split current change interactively
jj split

# Split specific revision
jj split -r REV
```

### Absorb (Smart Amend)

```bash
# Automatically amend changes into appropriate commits
jj absorb
```

### Operation Undo

```bash
# View operation history
jj op log

# Undo last operation
jj undo

# Restore to specific operation
jj op restore OP_ID

# Show operation diff
jj op diff OP_ID
```

### Parallelizing History

```bash
# Make two commits parallel (unrelated)
jj parallelize A B
```

### File Operations

```bash
# Show file at revision
jj file show FILE -r REV

# Annotate (blame)
jj file annotate FILE

# List tracked files
jj file list
```

### Templates

```bash
# Custom log format
jj log -T 'change_id ++ " " ++ description'

# Available template keywords
# change_id, commit_id, author, committer, description
# empty, conflict, branches, tags, working_copies
```

## Revset Syntax Reference

| Expression             | Meaning                                       |
| ---------------------- | --------------------------------------------- |
| `@`                    | Working copy                                  |
| `@-`                   | Parent of working copy                        |
| `@--`                  | Grandparent                                   |
| `REV-`                 | Parent of REV                                 |
| `REV+`                 | Children of REV                               |
| `root()`               | Root commit                                   |
| `heads()`              | All heads                                     |
| `bookmarks()`          | All bookmarks                                 |
| `remote_bookmarks()`   | Remote bookmarks                              |
| `tags()`               | All tags                                      |
| `trunk()`              | Trunk bookmark                                |
| `visible_heads()`      | Visible heads                                 |
| `A..B`                 | Ancestors of B not ancestors of A (exclusive) |
| `A::B`                 | A to B inclusive                              |
| `::B`                  | All ancestors of B                            |
| `A::`                  | A and all descendants                         |
| `A \| B`               | Union                                         |
| `A & B`                | Intersection                                  |
| `A ~ B`                | Difference (A minus B)                        |
| `~A`                   | Complement                                    |
| `A-`                   | Parents                                       |
| `A+`                   | Children                                      |
| `all()`                | All commits                                   |
| `none()`               | Empty set                                     |
| `present(x)`           | x if exists, else empty                       |
| `empty()`              | Empty commits                                 |
| `conflict()`           | Commits with conflicts                        |
| `author(pattern)`      | By author                                     |
| `committer(pattern)`   | By committer                                  |
| `description(pattern)` | By description                                |
| `file(pattern)`        | Commits touching file                         |
