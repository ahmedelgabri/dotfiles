---
description: Interact with Jira using natural language
argument-hint: <natural language request>
allowed-tools: Bash(jira:*)
---

# Jira Command

Interact with Jira issues using natural language. This command translates your
request into the appropriate `jira` CLI commands.

## Arguments

The user's request: $ARGUMENTS

## Instructions

Use the jira skill knowledge to interpret the user's natural language request
and execute the appropriate `jira` CLI command(s).

### Examples of natural language requests

- "show my issues" -> list issues assigned to me
- "what am I working on" -> list my in-progress issues
- "show PROJ-123" -> view issue details
- "move PROJ-123 to done" -> transition issue
- "assign PROJ-123 to me" -> assign issue to self
- "create a bug about login failing" -> create a new bug issue
- "comment on PROJ-123 that this is fixed" -> add a comment
- "open PROJ-123" -> open issue in browser
- "list bugs in the current sprint" -> filter issues by type and sprint
- "what issues are blocked" -> search for blocked issues

## Response format

1. Show the `jira` command you are about to run
2. Execute the command
3. Present the results clearly

If the request is ambiguous, ask for clarification before running commands.
