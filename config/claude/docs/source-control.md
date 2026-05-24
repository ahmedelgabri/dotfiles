# Source Control

- Prefer the repository's native VCS for repository-changing workflows.
- In Jujutsu repositories (`.jj` present, including colocated `.jj` + `.git`
  repos), use `jj` for changing history or the working copy; raw Git is fine for
  read-only inspection only.
- In Jujutsu repositories, avoid raw `git add`, `git stage`, `git history`, and
  `git commit`.
- In Git-only repositories, use Git normally.
- Commit messages should be concise, descriptive, and formatted as Conventional
  Commits.
- Commit subjects should use the imperative mood and present tense, with an
  appropriate type prefix such as `feat:`, `fix:`, `docs:`, `chore:`,
  `refactor:`, or `test:` and an optional scope.
