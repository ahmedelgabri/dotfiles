# `/simplify`

Review changed code with four independent Pi processes, then have the current agent deduplicate their findings and apply behavior-preserving cleanup. The reviewers cover reuse, simplification, efficiency, and root-cause depth. This is a quality review, not a correctness or bug review.

## Load and run

Home Manager links the extension on rebuild. In an existing Pi session, run `/reload` after rebuilding. To use it without rebuilding, start Pi with:

```sh
pi -e ~/.dotfiles/config/pi/agent/extensions/simplify.ts
```

Run `/simplify` in an idle interactive or RPC session. Print and JSON batch modes are rejected because Pi can exit before the asynchronous apply turn finishes.

| Command                              | Scope                                                                         |
| ------------------------------------ | ----------------------------------------------------------------------------- |
| `/simplify`                          | Default branch or revision diff, including working changes as described below |
| `/simplify --`                       | Working changes only                                                          |
| `/simplify -- src/`                  | Working changes under a path                                                  |
| `/simplify -- "path with spaces.ts"` | A specific working-tree file                                                  |
| `/simplify jj 'main..@'`             | A Jujutsu revision range                                                      |
| `/simplify ref main...HEAD`          | A Git branch range                                                            |
| `/simplify ref HEAD`                 | A single Git commit                                                           |
| `/simplify pr 42`                    | A GitHub PR, fetched through `gh`                                             |
| `/simplify cancel`                   | Cancel the active review before the apply handoff                             |

Other explicit targets follow the existing [`/diff` argument rules](diff/README.md#the-diff-command), including PR URLs and automatic ref detection. A bare Git branch name resolves to its tip commit; use a range to review all branch changes. To review a file named `cancel`, use `/simplify -- cancel`.

With no arguments, Jujutsu uses the existing `/diff` default of `main`, `master`, or `trunk()` through `@`, falling back to the working revision. Git tries `@{upstream}`, `main`, then `HEAD~1` as the base and appends `git diff HEAD` when there are working changes. Git untracked files are not included, matching `git diff HEAD`. Explicit targets do not add unrelated working changes. The `/diff` command's own defaults are unchanged.

## Review and apply

Each reviewer inherits the model and thinking level selected when the review starts. If Pi exposes no thinking level for that model, the extension omits `--thinking` and lets the child resolve its default. The child processes use the installed `pi` executable and its configured credentials and models. They do not inherit conversation history, ephemeral provider registrations, or extension tools. Extension, skill, prompt-template, and theme discovery are disabled in the children; normal context-file loading remains enabled.

The reviewers receive the same captured patch and one review angle. They can inspect files with `read` and search with `rg` and `fd` through `bash`. They are instructed not to modify files, run project code, or use network services. This is an instruction-level restriction, not a filesystem sandbox, because `bash` remains available.

All four reviews must finish successfully. Each has a 15-minute timeout. Failures, incomplete responses, malformed JSON streams, and stderr diagnostics stop the apply handoff. Cancellation and session shutdown abort the subprocesses. The extension checks the diff again before sending the reports to the parent and refuses to apply stale findings.

The parent reads all reports, deduplicates findings, verifies them against the checkout and repository instructions, and applies the smallest fixes. It skips false positives, behavior changes, unrelated refactors, and findings that do not match the checked-out target. No branch checkout or history rewrite is requested. Once the apply turn starts, use Pi's normal abort controls rather than `/simplify cancel`.

The efficiency reviewer flags retained closure data only when it can identify the data and its lifetime. It does not treat closures themselves as memory leaks.

## Files and requirements

The captured scope and reports are stored in a private `pi-simplify-*` temporary directory with mode-0600 files. Failed or cancelled runs remove that directory. Successful runs retain it so the parent can read the reports; their paths appear in the handoff message and can be removed after the apply turn finishes.

The selected model must be available to a fresh Pi process. Four reviewers incur separate model usage in addition to the parent apply turn; their usage is not included in the parent's token and cost counters. PR targets require `gh` authentication. `git` or `jj`, plus `pi`, `rg`, and `fd`, must be available on PATH.

## Validation

The test scripts under `scripts/tests/` are kept local, not committed. With those scripts available, run from the repository root:

```sh
bun test scripts/tests/pi-simplify.test.ts
PI_PROVIDER=openai-codex PI_MODEL='your-authenticated-model-id' bun run scripts/tests/pi-simplify.e2e.ts
```

The first command covers parsing, real Git and Jujutsu repositories, PR dispatch, four-way concurrency, model inheritance, failures, cancellation, stale diffs, and command lifecycle. Its child-process and PR-response substitutes are confined to unit and integration tests.

The end-to-end test uses real Pi subprocesses, a real model API, and a temporary Git repository. It invokes `/simplify` through RPC and verifies that the parent replaces duplicated normalization with an existing helper, preserves behavior, and does not change repository history. It uses no mocks and incurs model usage. Failed test fixtures retain their event logs for diagnosis; successful fixtures are removed.
