---
name: github
<!-- prettier-ignore-start -->
description: This skill should be used when the user mentions GitHub PRs, issues, workflows, releases, or repository management. Triggers on keywords like "github", "gh", "pr", "pull request", "issue", "workflow", "actions", "release", "merge", "review", "ci", "check", or PR/issue number patterns like "#123".
<!-- prettier-ignore-end -->
version: 1.0.0
---

# GitHub CLI Skill

This skill enables natural language interaction with GitHub via the `gh` CLI
tool (https://cli.github.com/).

## Quick Reference

| Intent          | Command                                |
| --------------- | -------------------------------------- |
| View PR         | `gh pr view NUMBER`                    |
| List PRs        | `gh pr list`                           |
| My PRs          | `gh pr list --author @me`              |
| Create PR       | `gh pr create -t "Title" -b "Body"`    |
| PR status       | `gh pr status`                         |
| Merge PR        | `gh pr merge NUMBER`                   |
| View issue      | `gh issue view NUMBER`                 |
| List issues     | `gh issue list`                        |
| Create issue    | `gh issue create -t "Title" -b "Body"` |
| Workflow runs   | `gh run list`                          |
| View run        | `gh run view RUN-ID`                   |
| Repo info       | `gh repo view`                         |
| Open in browser | `gh browse`                            |

## Pull Requests

### Viewing PRs

```bash
# View PR in terminal
gh pr view NUMBER

# View PR in browser
gh pr view NUMBER --web

# View PR with comments
gh pr view NUMBER --comments

# View PR diff
gh pr diff NUMBER

# View PR checks/CI status
gh pr checks NUMBER

# View PR files changed
gh pr diff NUMBER --name-only

# View current branch's PR
gh pr view

# Get PR as JSON (for scripting)
gh pr view NUMBER --json number,title,state,mergeable,reviewDecision
```

### Listing PRs

```bash
# List open PRs
gh pr list

# List my PRs
gh pr list --author @me

# List PRs assigned to me for review
gh pr list --search "review-requested:@me"

# List PRs by state
gh pr list --state open
gh pr list --state closed
gh pr list --state merged
gh pr list --state all

# List PRs by label
gh pr list --label bug
gh pr list --label "needs review"

# List PRs by base branch
gh pr list --base main
gh pr list --base develop

# List PRs by head branch
gh pr list --head feature/my-branch

# List draft PRs
gh pr list --draft

# Search PRs
gh pr list --search "fix login"
gh pr list --search "author:username"
gh pr list --search "is:open is:draft"

# Limit results
gh pr list --limit 10

# JSON output for scripting
gh pr list --json number,title,author,createdAt

# Web view of PR list
gh pr list --web
```

### Creating PRs

```bash
# Interactive PR creation
gh pr create

# Non-interactive with title and body
gh pr create --title "Add feature X" --body "Description here"

# Create with specific base branch
gh pr create --base develop

# Create draft PR
gh pr create --draft --title "WIP: Feature"

# Create and request reviewers
gh pr create --title "Feature" --reviewer user1,user2

# Create with assignees
gh pr create --title "Feature" --assignee @me,user2

# Create with labels
gh pr create --title "Fix" --label bug,urgent

# Create with milestone
gh pr create --title "Feature" --milestone "v1.0"

# Create with project
gh pr create --title "Feature" --project "Project Name"

# Create from issue (links PR to issue)
gh pr create --title "Fix #123" --body "Closes #123"

# Fill title/body from commit messages
gh pr create --fill

# Fill from specific commit
gh pr create --fill-first

# Use template
gh pr create --template bug_report.md

# Create and open in browser
gh pr create --title "Feature" --web

# Read body from file
gh pr create --title "Feature" --body-file DESCRIPTION.md
```

### PR Status and Checks

```bash
# Show status of PRs relevant to you
gh pr status

# Check CI status for a PR
gh pr checks NUMBER

# Watch CI status (updates live)
gh pr checks NUMBER --watch

# Wait for checks to complete
gh pr checks NUMBER --watch --fail-fast

# Check specific PR's review status
gh pr view NUMBER --json reviewDecision,reviews

# List required checks
gh pr checks NUMBER --required
```

### Reviewing PRs

```bash
# Start a review
gh pr review NUMBER

# Approve PR
gh pr review NUMBER --approve

# Request changes
gh pr review NUMBER --request-changes --body "Please fix X"

# Comment without approval/rejection
gh pr review NUMBER --comment --body "Looks good overall"

# View PR diff for review
gh pr diff NUMBER

# Checkout PR locally for testing
gh pr checkout NUMBER

# Checkout PR to specific branch
gh pr checkout NUMBER --branch test-pr-123

# Add comment to PR
gh pr comment NUMBER --body "Comment text"

# Edit PR comment
gh pr comment NUMBER --edit-last --body "Updated comment"
```

### Merging PRs

```bash
# Merge PR (uses repo default method)
gh pr merge NUMBER

# Merge with specific method
gh pr merge NUMBER --merge  # Create merge commit
gh pr merge NUMBER --squash # Squash and merge
gh pr merge NUMBER --rebase # Rebase and merge

# Merge and delete branch
gh pr merge NUMBER --delete-branch

# Auto-merge when checks pass
gh pr merge NUMBER --auto

# Disable auto-merge
gh pr merge NUMBER --disable-auto

# Merge with custom commit message
gh pr merge NUMBER --squash --subject "feat: add feature" --body "Details"

# Admin merge (bypass protections)
gh pr merge NUMBER --admin
```

### Editing PRs

```bash
# Edit PR title
gh pr edit NUMBER --title "New title"

# Edit PR body
gh pr edit NUMBER --body "New description"

# Add labels
gh pr edit NUMBER --add-label bug,urgent

# Remove labels
gh pr edit NUMBER --remove-label wip

# Add reviewers
gh pr edit NUMBER --add-reviewer user1,user2

# Remove reviewers
gh pr edit NUMBER --remove-reviewer user1

# Add assignees
gh pr edit NUMBER --add-assignee @me

# Set milestone
gh pr edit NUMBER --milestone "v1.0"

# Convert to draft
gh pr ready NUMBER --undo

# Mark ready for review
gh pr ready NUMBER

# Set base branch
gh pr edit NUMBER --base develop
```

### Closing/Reopening PRs

```bash
# Close PR
gh pr close NUMBER

# Close with comment
gh pr close NUMBER --comment "Closing because..."

# Close and delete branch
gh pr close NUMBER --delete-branch

# Reopen PR
gh pr reopen NUMBER
```

## Issues

### Viewing Issues

```bash
# View issue
gh issue view NUMBER

# View in browser
gh issue view NUMBER --web

# View with comments
gh issue view NUMBER --comments

# Get issue as JSON
gh issue view NUMBER --json number,title,state,labels,assignees
```

### Listing Issues

```bash
# List open issues
gh issue list

# List my issues
gh issue list --assignee @me

# List issues I created
gh issue list --author @me

# List issues mentioning me
gh issue list --mention @me

# List by state
gh issue list --state open
gh issue list --state closed
gh issue list --state all

# List by label
gh issue list --label bug
gh issue list --label "help wanted"

# List by milestone
gh issue list --milestone "v1.0"

# Search issues
gh issue list --search "login error"
gh issue list --search "is:open label:bug"

# Limit results
gh issue list --limit 20

# JSON output
gh issue list --json number,title,labels,createdAt

# Web view
gh issue list --web
```

### Creating Issues

```bash
# Interactive creation
gh issue create

# Non-interactive
gh issue create --title "Bug: X not working" --body "Description"

# Create with labels
gh issue create --title "Bug" --label bug,urgent

# Create with assignees
gh issue create --title "Task" --assignee @me,user2

# Create with milestone
gh issue create --title "Feature" --milestone "v1.0"

# Create with project
gh issue create --title "Feature" --project "Project Name"

# Use template
gh issue create --template bug_report.md

# Read body from file
gh issue create --title "Feature" --body-file ISSUE.md

# Create and open in browser
gh issue create --title "Bug" --web

# Create from current branch name
gh issue create --recover
```

### Editing Issues

```bash
# Edit title
gh issue edit NUMBER --title "New title"

# Edit body
gh issue edit NUMBER --body "New description"

# Add labels
gh issue edit NUMBER --add-label bug,urgent

# Remove labels
gh issue edit NUMBER --remove-label wip

# Add assignees
gh issue edit NUMBER --add-assignee user1

# Remove assignees
gh issue edit NUMBER --remove-assignee user1

# Set milestone
gh issue edit NUMBER --milestone "v1.0"

# Add to project
gh issue edit NUMBER --add-project "Project Name"
```

### Closing/Reopening Issues

```bash
# Close issue
gh issue close NUMBER

# Close with comment
gh issue close NUMBER --comment "Fixed in #PR"

# Close as completed
gh issue close NUMBER --reason completed

# Close as not planned
gh issue close NUMBER --reason "not planned"

# Reopen issue
gh issue reopen NUMBER
```

### Issue Comments

```bash
# Add comment
gh issue comment NUMBER --body "Comment text"

# Edit last comment
gh issue comment NUMBER --edit-last --body "Updated"

# Open comment editor
gh issue comment NUMBER --editor
```

### Linking Issues and PRs

```bash
# Create PR that closes issue
gh pr create --title "Fix #123" --body "Closes #123"

# Link issue in PR body
gh pr create --body "Fixes #123, Related to #456"

# Develop on issue (create branch)
gh issue develop NUMBER

# Develop with custom branch name
gh issue develop NUMBER --name feature/fix-issue

# Develop and checkout
gh issue develop NUMBER --checkout
```

## Workflows and Actions

### Listing Runs

```bash
# List recent workflow runs
gh run list

# List runs for specific workflow
gh run list --workflow build.yml

# List runs by status
gh run list --status success
gh run list --status failure
gh run list --status in_progress

# List runs for branch
gh run list --branch main

# List runs for user
gh run list --user @me

# Limit results
gh run list --limit 10

# JSON output
gh run list --json databaseId,status,conclusion,name

# Web view
gh run list --web
```

### Viewing Runs

```bash
# View run details
gh run view RUN-ID

# View run in browser
gh run view RUN-ID --web

# View specific job
gh run view RUN-ID --job JOB-ID

# View run log
gh run view RUN-ID --log

# View failed job logs only
gh run view RUN-ID --log-failed

# Exit with run's exit code
gh run view RUN-ID --exit-status

# Watch run progress
gh run watch RUN-ID

# Get run as JSON
gh run view RUN-ID --json status,conclusion,jobs
```

### Managing Runs

```bash
# Rerun failed jobs
gh run rerun RUN-ID --failed

# Rerun all jobs
gh run rerun RUN-ID

# Rerun specific job
gh run rerun RUN-ID --job JOB-ID

# Rerun with debug logging
gh run rerun RUN-ID --debug

# Cancel a run
gh run cancel RUN-ID

# Delete a run
gh run delete RUN-ID

# Download run artifacts
gh run download RUN-ID

# Download specific artifact
gh run download RUN-ID --name artifact-name

# Download to specific directory
gh run download RUN-ID --dir ./artifacts
```

### Triggering Workflows

```bash
# Trigger workflow (workflow_dispatch)
gh workflow run workflow.yml

# Trigger with inputs
gh workflow run workflow.yml -f param1=value1 -f param2=value2

# Trigger on specific branch
gh workflow run workflow.yml --ref feature-branch

# Trigger from JSON file
gh workflow run workflow.yml --json <inputs.json
```

### Listing Workflows

```bash
# List all workflows
gh workflow list

# List enabled workflows
gh workflow list --state enabled

# List disabled workflows
gh workflow list --state disabled

# View specific workflow
gh workflow view workflow.yml

# View workflow in browser
gh workflow view workflow.yml --web

# Enable workflow
gh workflow enable workflow.yml

# Disable workflow
gh workflow disable workflow.yml
```

## Repository Management

### Viewing Repos

```bash
# View current repo
gh repo view

# View specific repo
gh repo view owner/repo

# View in browser
gh repo view --web

# Get repo as JSON
gh repo view --json name,description,stargazerCount,forkCount

# View README
gh repo view --readme
```

### Cloning and Forking

```bash
# Clone repo
gh repo clone owner/repo

# Clone to specific directory
gh repo clone owner/repo ./my-dir

# Fork repo
gh repo fork owner/repo

# Fork and clone
gh repo fork owner/repo --clone

# Fork with custom name
gh repo fork owner/repo --fork-name my-fork
```

### Creating Repos

```bash
# Create repo interactively
gh repo create

# Create public repo
gh repo create my-repo --public

# Create private repo
gh repo create my-repo --private

# Create from template
gh repo create my-repo --template owner/template

# Create and clone
gh repo create my-repo --clone

# Create with description
gh repo create my-repo --description "My project"

# Create with gitignore
gh repo create my-repo --gitignore Node

# Create with license
gh repo create my-repo --license MIT

# Create org repo
gh repo create org/my-repo
```

### Editing Repos

```bash
# Edit description
gh repo edit --description "New description"

# Set homepage
gh repo edit --homepage "https://example.com"

# Change visibility
gh repo edit --visibility private
gh repo edit --visibility public

# Enable/disable features
gh repo edit --enable-issues
gh repo edit --enable-wiki=false
gh repo edit --enable-discussions

# Set default branch
gh repo edit --default-branch main

# Enable auto-merge
gh repo edit --enable-auto-merge

# Enable delete branch on merge
gh repo edit --delete-branch-on-merge

# Archive repo
gh repo archive
gh repo archive owner/repo

# Unarchive
gh repo unarchive owner/repo

# Delete repo
gh repo delete owner/repo --yes
```

### Repository Secrets

```bash
# List secrets
gh secret list

# Set secret
gh secret set SECRET_NAME

# Set secret from env
gh secret set SECRET_NAME --body "$VALUE"

# Set secret from file
gh secret set SECRET_NAME <secret.txt

# Set environment secret
gh secret set SECRET_NAME --env production

# Set org secret
gh secret set SECRET_NAME --org my-org

# Remove secret
gh secret delete SECRET_NAME
```

### Repository Variables

```bash
# List variables
gh variable list

# Set variable
gh variable set VAR_NAME --body "value"

# Set environment variable
gh variable set VAR_NAME --env production --body "value"

# Delete variable
gh variable delete VAR_NAME
```

## Releases

### Listing Releases

```bash
# List releases
gh release list

# List with limit
gh release list --limit 10

# Exclude drafts
gh release list --exclude-drafts

# Exclude pre-releases
gh release list --exclude-pre-releases
```

### Viewing Releases

```bash
# View latest release
gh release view

# View specific release
gh release view v1.0.0

# View in browser
gh release view v1.0.0 --web

# Get as JSON
gh release view v1.0.0 --json tagName,name,body,assets
```

### Creating Releases

```bash
# Create release interactively
gh release create v1.0.0

# Create with title and notes
gh release create v1.0.0 --title "Version 1.0" --notes "Release notes"

# Create from file
gh release create v1.0.0 --notes-file CHANGELOG.md

# Auto-generate release notes
gh release create v1.0.0 --generate-notes

# Create draft
gh release create v1.0.0 --draft

# Create pre-release
gh release create v1.0.0 --prerelease

# Create with assets
gh release create v1.0.0 ./dist/*.zip ./dist/*.tar.gz

# Create from specific commit/branch
gh release create v1.0.0 --target main

# Set as latest
gh release create v1.0.0 --latest

# Don't mark as latest
gh release create v1.0.0 --latest=false

# Create and open discussion
gh release create v1.0.0 --discussion-category "Announcements"
```

### Editing Releases

```bash
# Edit release
gh release edit v1.0.0 --title "New Title"

# Edit notes
gh release edit v1.0.0 --notes "Updated notes"

# Convert draft to published
gh release edit v1.0.0 --draft=false

# Mark as pre-release
gh release edit v1.0.0 --prerelease

# Set as latest
gh release edit v1.0.0 --latest
```

### Managing Release Assets

```bash
# Upload assets
gh release upload v1.0.0 ./dist/*.zip

# Upload with custom name
gh release upload v1.0.0 ./build/app.zip#app-v1.0.0.zip

# Overwrite existing
gh release upload v1.0.0 ./dist/app.zip --clobber

# Download assets
gh release download v1.0.0

# Download specific asset
gh release download v1.0.0 --pattern "*.zip"

# Download to directory
gh release download v1.0.0 --dir ./downloads

# Delete asset
gh release delete-asset v1.0.0 app.zip
```

### Deleting Releases

```bash
# Delete release
gh release delete v1.0.0

# Delete release and tag
gh release delete v1.0.0 --yes

# Cleanup old releases (delete drafts)
gh release delete v1.0.0-draft --yes
```

## Gists

```bash
# List gists
gh gist list

# View gist
gh gist view GIST-ID

# View in browser
gh gist view GIST-ID --web

# Create gist
gh gist create file.txt

# Create public gist
gh gist create file.txt --public

# Create with description
gh gist create file.txt --desc "My gist"

# Create from multiple files
gh gist create file1.txt file2.js

# Create from stdin
echo "content" | gh gist create

# Edit gist
gh gist edit GIST-ID

# Add file to gist
gh gist edit GIST-ID --add newfile.txt

# Clone gist
gh gist clone GIST-ID

# Delete gist
gh gist delete GIST-ID
```

## Browsing

```bash
# Open repo in browser
gh browse

# Open specific file
gh browse path/to/file.js

# Open at specific line
gh browse path/to/file.js:42

# Open specific branch
gh browse --branch develop

# Open commit
gh browse --commit abc123

# Open PRs page
gh browse --prs

# Open issues page
gh browse --issues

# Open actions page
gh browse --actions

# Open settings
gh browse --settings

# Open wiki
gh browse --wiki

# Open projects
gh browse --projects

# Print URL only (don't open)
gh browse --no-browser
```

## Code Search and Codespaces

### Code Search

```bash
# Search code in repo
gh search code "function" --repo owner/repo

# Search across GitHub
gh search code "pattern" --language javascript

# Search repos
gh search repos "topic:react" --limit 10

# Search issues
gh search issues "bug" --repo owner/repo

# Search PRs
gh search prs "fix" --state open

# Search commits
gh search commits "fix bug" --repo owner/repo
```

### Codespaces

```bash
# List codespaces
gh codespace list

# Create codespace
gh codespace create --repo owner/repo

# Create with specific branch
gh codespace create --repo owner/repo --branch feature

# Create with machine type
gh codespace create --repo owner/repo --machine largePremiumLinux

# SSH into codespace
gh codespace ssh --codespace NAME

# Open in VS Code
gh codespace code --codespace NAME

# Open in browser
gh codespace view --codespace NAME --web

# Stop codespace
gh codespace stop --codespace NAME

# Delete codespace
gh codespace delete --codespace NAME

# Port forwarding
gh codespace ports forward 3000:3000 --codespace NAME
```

## Authentication and Configuration

```bash
# Login
gh auth login

# Login with specific host
gh auth login --hostname enterprise.github.com

# Login with token
gh auth login --with-token <token.txt

# Check auth status
gh auth status

# Refresh auth
gh auth refresh

# Switch accounts
gh auth switch

# Logout
gh auth logout

# View current user
gh api user --jq .login

# Set git protocol
gh config set git_protocol ssh

# Set default editor
gh config set editor vim

# Set default browser
gh config set browser firefox

# View config
gh config list
```

## API Access

```bash
# Make API request
gh api repos/owner/repo

# POST request
gh api repos/owner/repo/issues -f title="Bug" -f body="Description"

# Use jq for filtering
gh api repos/owner/repo --jq '.stargazers_count'

# Paginate results
gh api repos/owner/repo/issues --paginate

# GraphQL query
gh api graphql -f query='{ viewer { login } }'

# Include headers in output
gh api repos/owner/repo --include
```

## Natural Language Mapping

When interpreting user requests, map these patterns:

| User says                      | Interpret as                         |
| ------------------------------ | ------------------------------------ |
| "my PRs", "my pull requests"   | `--author @me`                       |
| "PRs for review", "to review"  | `--search "review-requested:@me"`    |
| "open PRs"                     | `--state open`                       |
| "merged PRs"                   | `--state merged`                     |
| "closed PRs/issues"            | `--state closed`                     |
| "draft PRs"                    | `--draft`                            |
| "bugs", "bug issues"           | `--label bug`                        |
| "my issues"                    | `--assignee @me`                     |
| "issues I created"             | `--author @me`                       |
| "failing CI", "failed checks"  | `gh pr checks` or `--status failure` |
| "CI status", "check status"    | `gh pr checks NUMBER`                |
| "recent runs", "workflow runs" | `gh run list`                        |
| "open it", "show in browser"   | `--web` or `gh browse`               |
| "merge it"                     | `gh pr merge`                        |
| "approve", "LGTM"              | `gh pr review --approve`             |
| "request changes"              | `gh pr review --request-changes`     |
| "latest release"               | `gh release view`                    |
| "create release"               | `gh release create`                  |
| "checkout PR"                  | `gh pr checkout NUMBER`              |
| "PR diff", "what changed"      | `gh pr diff NUMBER`                  |

## PR/Issue Detection

PR and issue numbers follow patterns: `#123`, `PR #123`, `issue #123`

When a user mentions a number in conversation:

- Offer to view: `gh pr view NUMBER` or `gh issue view NUMBER`
- Or open: `gh browse` with the appropriate path

## Tips

1. Always show the command before running it
2. Use `--json` for scripting and parsing output
3. Use `@me` to reference the current user
4. Use `--web` to open results in browser
5. Use `--help` on any command for more options
6. The `-R owner/repo` flag can override the current repo context
7. Use `gh api` for operations not covered by specific commands
8. Enable shell completion: `gh completion -s bash/zsh/fish`

## Error Handling

Common issues:

- "not found" - verify repo access and PR/issue number
- "not authenticated" - run `gh auth login`
- "merge blocked" - check required reviews/checks
- "no upstream" - push branch first: `git push -u origin branch`
- "draft PR" - mark ready with `gh pr ready NUMBER`
