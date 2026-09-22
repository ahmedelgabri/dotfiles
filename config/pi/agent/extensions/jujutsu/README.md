# Jujutsu

Show the current jj change in Pi's footer and discourage agent-issued Git writes in jj repositories. Detection walks upward from the session's working directory to find `.jj`, including colocated repositories and secondary workspaces.

## Footer

The interactive footer shows `[workspace] change[*][✗] bookmarks`. The default workspace name is omitted, `*` marks a nonempty working-copy revision, and a red `✗` marks conflicts. Bookmarks include the nearest bookmarked ancestors, so they remain visible when the working-copy revision has no bookmark itself.

The extension requires `jj` on PATH and the shared `prompt_revs()` and `prompt_fields()` aliases from [`config/jj/config.toml`](../../../../jj/config.toml). Queries pass `--ignore-working-copy`; the dirty marker reflects jj's recorded revision, not filesystem edits that have not been snapshotted.

Status refreshes on session start and when jj's operation heads change. `/jj-refresh` forces a refresh, which is useful if filesystem watching is unavailable. Failed queries clear the footer rather than showing stale data. Footer rendering is terminal-UI-only.

## Agent guard

In a detected jj repository, the extension adds a repository instruction and blocks common `git add`, `git stage`, `git history`, and `git commit` forms issued through the `bash` tool. Read-only Git inspection remains available.

This is a regex-based guardrail, not a shell parser or security boundary. It does not intercept commands outside the Bash tool, and it uses the repository detected at session start rather than following `cd` inside shell commands.

See [extension loading](../README.md#activation).
