---
name: jira
<!-- prettier-ignore-start -->
description: This skill should be used when the user mentions Jira issues (e.g., "PROJ-123"), asks about tickets, wants to create/view/update issues, check sprint status, or manage their Jira workflow. Triggers on keywords like "jira", "issue", "ticket", "sprint", "backlog", or issue key patterns.
<!-- prettier-ignore-end -->
version: 1.0.0
---

# Jira CLI Skill

This skill enables natural language interaction with Jira via the `jira` CLI
tool (https://github.com/ankitpokhrel/jira-cli).

## Quick Reference

| Intent          | Command                                                |
| --------------- | ------------------------------------------------------ |
| View issue      | `jira issue view ISSUE-KEY`                            |
| List my issues  | `jira issue list -a$(jira me)`                         |
| My in-progress  | `jira issue list -a$(jira me) -s"In Progress"`         |
| Create issue    | `jira issue create -tType -s"Summary" -b"Description"` |
| Move/transition | `jira issue move ISSUE-KEY "State"`                    |
| Assign to me    | `jira issue assign ISSUE-KEY $(jira me)`               |
| Unassign        | `jira issue assign ISSUE-KEY x`                        |
| Add comment     | `jira issue comment add ISSUE-KEY -b"Comment text"`    |
| Open in browser | `jira open ISSUE-KEY`                                  |
| Current sprint  | `jira sprint list --state active`                      |
| Who am I        | `jira me`                                              |

## Command Details

### Viewing Issues

```bash
# View single issue
jira issue view ISSUE-KEY

# View with more comments
jira issue view ISSUE-KEY --comments 5

# Get raw JSON
jira issue view ISSUE-KEY --raw
```

### Listing Issues

```bash
# List all issues in project
jira issue list

# List my issues
jira issue list -a$(jira me)

# Filter by status (use quotes for multi-word statuses)
jira issue list -s"In Progress"
jira issue list -s"To Do"
jira issue list -sDone

# Filter by type
jira issue list -tBug
jira issue list -tStory
jira issue list -tTask
jira issue list -tEpic

# Filter by priority
jira issue list -yHigh
jira issue list -yCritical

# Filter by label
jira issue list -lurgent -lbug

# Combine filters
jira issue list -a$(jira me) -s"In Progress" -yHigh

# Search with text
jira issue list "login error"

# Recently accessed
jira issue list --history

# Issues I'm watching
jira issue list -w

# Created/updated filters
jira issue list --created today
jira issue list --created week
jira issue list --updated -2d

# Plain output for scripting
jira issue list --plain --no-headers

# Specific columns
jira issue list --plain --columns key,summary,status,assignee

# Raw JQL query
jira issue list -q"status = 'In Progress' AND assignee = currentUser()"

# Paginate results
jira issue list --paginate 20
jira issue list --paginate 10:50 # start:limit
```

### Creating Issues

```bash
# Interactive creation
jira issue create

# Non-interactive with all fields
jira issue create \
	-tBug \
	-s"Login button not working" \
	-b"Users cannot click the login button on Safari" \
	-yHigh \
	-lbug -lurgent

# Create and assign to self
jira issue create -tTask -s"Summary" -a$(jira me)

# Create subtask (requires parent)
jira issue create -tSub-task -P"PROJ-123" -s"Subtask summary"

# Create with custom fields
jira issue create -tStory -s"Summary" --custom story-points=3

# Skip prompts for optional fields
jira issue create -tTask -s"Quick task" --no-input

# Open in browser after creation
jira issue create -tBug -s"Bug title" --web

# Read description from file
jira issue create -tStory -s"Summary" --template /path/to/template.md

# Read description from stdin
echo "Description here" | jira issue create -tTask -s"Summary"
```

### Transitioning Issues

```bash
# Move to a state
jira issue move ISSUE-KEY "In Progress"
jira issue move ISSUE-KEY "Done"
jira issue move ISSUE-KEY "To Do"

# Move with comment
jira issue move ISSUE-KEY "Done" --comment "Completed the implementation"

# Move and set resolution
jira issue move ISSUE-KEY "Done" -R"Fixed"

# Move and reassign
jira issue move ISSUE-KEY "In Review" -a"reviewer@example.com"

# Open in browser after transition
jira issue move ISSUE-KEY "Done" --web
```

### Assigning Issues

```bash
# Assign to specific user
jira issue assign ISSUE-KEY "user@example.com"
jira issue assign ISSUE-KEY "John Doe"

# Assign to self
jira issue assign ISSUE-KEY $(jira me)

# Assign to default assignee
jira issue assign ISSUE-KEY default

# Unassign
jira issue assign ISSUE-KEY x
```

### Comments

```bash
# Add comment
jira issue comment add ISSUE-KEY -b"This is my comment"

# Add comment from file
jira issue comment add ISSUE-KEY --template /path/to/comment.md
```

### Sprints

```bash
# List sprints
jira sprint list

# Active sprint only
jira sprint list --state active

# Add issue to sprint
jira sprint add SPRINT-ID ISSUE-KEY

# Close sprint
jira sprint close SPRINT-ID
```

### Other Commands

```bash
# Open issue in browser
jira open ISSUE-KEY

# Show current user
jira me

# Server info
jira serverinfo

# List projects
jira project list

# List boards
jira board list
```

## Natural Language Mapping

When interpreting user requests, map these patterns:

| User says                       | Interpret as                          |
| ------------------------------- | ------------------------------------- |
| "my issues", "my tickets"       | `-a$(jira me)`                        |
| "in progress", "working on"     | `-s"In Progress"`                     |
| "todo", "to do", "backlog"      | `-s"To Do"`                           |
| "done", "completed", "finished" | `-sDone`                              |
| "bugs", "defects"               | `-tBug`                               |
| "stories", "features"           | `-tStory`                             |
| "tasks"                         | `-tTask`                              |
| "epics"                         | `-tEpic`                              |
| "high priority", "urgent"       | `-yHigh` or `-yCritical`              |
| "blocked"                       | `-s"Blocked"` or search for "blocked" |
| "this week"                     | `--created week` or `--updated week`  |
| "today"                         | `--created today`                     |
| "recent", "recently"            | `--history`                           |
| "watching"                      | `-w`                                  |
| "assign to me"                  | `$(jira me)`                          |
| "unassign"                      | `x`                                   |
| "open it", "show in browser"    | `jira open`                           |

## Issue Key Detection

Issue keys follow the pattern: `[A-Z]+-[0-9]+` (e.g., PROJ-123, ABC-1).

When a user mentions an issue key in conversation:

- Offer to view it: `jira issue view KEY`
- Or open it: `jira open KEY`

## Tips

1. Always show the command before running it
2. Use `--plain` for scripting or when output is too wide
3. Use `$(jira me)` to reference the current user
4. Quote multi-word status names: `-s"In Progress"`
5. Combine filters to narrow results
6. Use `--raw` when you need to parse JSON output
7. The `-p` flag can override the default project

## Error Handling

Common issues:

- "Issue does not exist" - verify the issue key
- "Transition not allowed" - check current status and available transitions
- "User not found" - use exact email or display name
