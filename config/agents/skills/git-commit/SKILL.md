---
name: git-commit
description: Create a commit (or draft a commit message) in a Git repository
---

# Create a commit (or draft a commit message) in a Git repository

Your user may invoke this skill explicitly with a slash command, or informally
with a phrase like "commit this" or "suggest a commit message". If they use a
loose instruction like "commit this" your first task is to determine whether you
are working in a Git repository and should make a Git commit (using this skill),
or you are working in a Jujutsu repo and should create a Jujutsu commit (using
the dedicated Jujutsu commit skill).

## Determining the repository type

**IMPORTANT:** Always identify the repository root of the current working
directory before making a commit. You must ensure that you are actually in a
repo, and that the repo uses the specific version control system that you intend
to use to create the commit.

Most frequently, you will be in a Git repository (which you can determine via
the presence of a `.git` directory and the absence of a `.jj` directory in the
current working directory's repository root). In Git repositories, you should
use this skill to create commits.

Less frequently, you will find yourself in a Jujutsu repository (which you can
determine via the presence of a `.jj` directory in the current working
directory's repository root). In Jujutsu repositories, you should use the
dedicated Jujutsu commit skill to create commits. For general information on
Jujutsu, see the Jujutsu version-control skill.

## Creating Git commits

Generally, if your user wants you to commit only a subset of the changes in the
working directory, they will instruct you to do so. Nevertheless, if you
determine that there are unrelated changes waiting to be committed, you should
clarify with the user how they wish to split them up into distinct commits,
rather than committing them all at once.

Usually, you will include all changes in the working directory in the commit
(that is, you should run `git diff` to see what the changes are, and/or
`git diff --staged` to see what has already been staged).

## Common instructions

1. Run commands to see what can and should be included in the commit.
2. Note that your user may have asked you to create or update "plan" files under
   `.agent-notes/`, a directory which may be ignored via the global
   `~/.config/git/ignore` file: these plan files should never be included in a
   commit as they are intended to be local-only aids to development.
3. Create a commit message with:
   - A subject of 72 characters or less in Conventional Commits format (eg.
     "docs: add migration notes" or "fix: avoid double-render in list
     component"). In repositories that make use of scopes, you can include a
     scope in parentheses (eg. "chore(frontend): update copyright year" or
     "feat(login): add support for magic links").
   - A blank line.
   - A detailed description, wrapped to 72 characters, using basic Markdown
     syntax.

## Best practices

- Subjects MUST start with a Conventional Commits type (eg. "docs", "fix",
  "feat", "chore" etc; see the table below for a full list) followed by a
  statement beginning with a verb (eg. "add", "remove", "rename" etc). The
  subject describes _what_ the commit does.
- The body should explain the motivation for the change, and why the solution
  was chosen.
- Note alternatives which were considered but not implemented.
- Include references to previous commits or other artifacts (documentation, PRs)
  that are relevant.

## Conventional Commits types

| Type     | When to use                                                                                        |
| -------- | -------------------------------------------------------------------------------------------------- |
| fix      | Bug fixes                                                                                          |
| feat     | New features                                                                                       |
| chore    | Content                                                                                            |
| refactor | Code improvements (eg. for better readability, easier maintenance etc) which don't change behavior |
| docs     | Documentation changes (including changes to code comments)                                         |
| test     | Changing or adding/removing tests                                                                  |
| perf     | Performance improvements                                                                           |
| style    | Formatting changes, automated lint fixes                                                           |

## Example

```
refactor: remove unused `recurse` setting

We were never exposing a user-accessible setting here. It is always `true`
in practice, except in the benchmarks where we offered an override via the
environment.

If there is ever a call for this in the future, we can resurrect it, but
for now, leaving it out presents us with an opportunity to simplify.
It may even be a tiny bit faster (1.3% better CPU time, and 2.4%
better wall time), with reasonable confidence, due to saving us some
conditional checks.
```
