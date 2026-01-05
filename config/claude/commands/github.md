---
description: Interact with GitHub using natural language
argument-hint: <natural language request>
allowed-tools: Bash(gh:*), Bash(command git:*)
---

# GitHub Command

Interact with GitHub PRs, issues, workflows, releases, and repositories using
natural language. This command translates your request into the appropriate `gh`
CLI commands.

## Arguments

The user's request: $ARGUMENTS

## Instructions

Use the github skill knowledge to interpret the user's natural language request
and execute the appropriate `gh` CLI command(s).

### Examples of natural language requests

**Pull Requests:**

- "show my PRs" -> list PRs authored by me
- "PRs waiting for my review" -> list PRs where review is requested from me
- "show PR #123" -> view PR details
- "what's the CI status on #123" -> check PR CI/checks status
- "merge #123" -> merge the PR
- "approve #123" -> approve the PR
- "checkout PR #123" -> checkout the PR locally
- "create a PR" -> create PR from current branch
- "create a draft PR for this branch" -> create draft PR
- "mark #123 ready for review" -> convert draft to ready
- "close PR #123" -> close the PR
- "diff for #123" -> show PR diff

**Issues:**

- "show my issues" -> list issues assigned to me
- "issues I created" -> list issues authored by me
- "show issue #456" -> view issue details
- "create an issue about the login bug" -> create new issue
- "close issue #456" -> close the issue
- "add label bug to #456" -> add label to issue
- "assign #456 to me" -> assign issue to self

**Workflows/Actions:**

- "show recent workflow runs" -> list workflow runs
- "what's failing in CI" -> list failed runs
- "rerun failed jobs for run 12345" -> rerun failed jobs
- "show logs for run 12345" -> view run logs
- "trigger the deploy workflow" -> run workflow_dispatch

**Releases:**

- "list releases" -> list all releases
- "show latest release" -> view latest release
- "create release v1.0.0" -> create new release
- "download release assets" -> download release artifacts

**Repository:**

- "open repo in browser" -> open GitHub page
- "show repo info" -> view repo details
- "who starred this repo" -> show stargazers
- "list repo secrets" -> list repository secrets

**General:**

- "open #123 in browser" -> open PR/issue in browser
- "search for login in code" -> search codebase
- "who am I logged in as" -> show current user

## Response format

1. Show the `gh` command(s) about to run
2. Execute the command(s)
3. Present the results clearly
4. Suggest follow-up actions when relevant

If the request is ambiguous (e.g., "#123" could be a PR or issue), check both or
ask for clarification.

## Context awareness

- If in a git repo, commands automatically use that repo context
- Use `-R owner/repo` to target a different repository
- Use `gh pr view` (no number) to view the PR for the current branch
- Detect PR/issue patterns: #123, PR #123, issue #123, or bare numbers in
  context
