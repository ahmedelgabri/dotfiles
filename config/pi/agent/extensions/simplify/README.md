# `/simplify`

Find and apply simplification opportunities across a codebase. Four independent Pi processes review the code under the current directory, or the paths you pass, then the current agent deduplicates their findings and applies behavior-preserving cleanup. The reviewers cover reuse, simplification, efficiency, and root-cause depth. This is a quality review, not a correctness or bug review.

## Load and run

Home Manager links the extension on rebuild. In an existing Pi session, run `/reload` after rebuilding. To use it without rebuilding, start Pi with:

```sh
pi -e ~/.dotfiles/config/pi/agent/extensions/simplify/index.ts
```

Run `/simplify` in an idle interactive or RPC session. Print and JSON batch modes are rejected because Pi can exit before the asynchronous apply turn finishes.

| Command                           | Scope                                             |
| --------------------------------- | ------------------------------------------------- |
| `/simplify`                       | Everything under the current directory            |
| `/simplify src/`                  | Everything under a path                           |
| `/simplify src/ lib/utils.ts`     | Several paths                                     |
| `/simplify "path with spaces.ts"` | A path with spaces                                |
| `/simplify cancel`                | Cancel the active review before the apply handoff |

Paths are relative to the current directory, and quoting follows the [`/diff` argument rules](../diff/README.md#the-diff-command). A path that does not exist stops the command before any reviewer starts. To review a file named `cancel`, use `/simplify ./cancel`.

The review does not depend on version control and covers the files as they are on disk, including uncommitted and untracked work. Outside a Jujutsu or Git repository, `/simplify` warns that the fixes cannot be reverted through version control and then continues. Inside a repository it does not warn.

## Review and apply

Each reviewer inherits the model and thinking level selected when the review starts. If Pi exposes no thinking level for that model, the extension omits `--thinking` and lets the child resolve its default. The child processes use the installed `pi` executable and its configured credentials and models. They do not inherit conversation history, ephemeral provider registrations, or extension tools. Extension, skill, prompt-template, and theme discovery are disabled in the children; normal context-file loading remains enabled.

The reviewers receive the same paths and one review angle each. They survey the code with `rg` and `fd` through `bash`, read the relevant files with `read`, skip generated, vendored, and dependency code, and report a few well-supported, high-impact findings rather than an exhaustive list. They are instructed not to modify files, run project code, or use network services. This is an instruction-level restriction, not a filesystem sandbox, because `bash` remains available.

All four reviews must finish successfully. Each has a 15-minute timeout, so on a large codebase pass narrower paths rather than reviewing everything at once. Failures, incomplete responses, malformed JSON streams, and stderr diagnostics stop the apply handoff. The one exception is pi's `No models match pattern` warning: reviewers inherit your settings, and pi prints it for every `enabledModels` entry its catalog lacks. A reviewer whose own model is missing still fails. Cancellation and session shutdown abort the subprocesses.

The parent reads all reports, deduplicates findings, verifies each against the current code and repository instructions, and applies the smallest fixes. Because it verifies against the files as they are when it applies, edits made while the reviewers run do not produce stale fixes. It skips false positives, behavior changes, and fixes that reach well outside the reviewed paths. No branch checkout or history rewrite is requested. Once the apply turn starts, use Pi's normal abort controls rather than `/simplify cancel`.

The efficiency reviewer flags retained closure data only when it can identify the data and its lifetime. It does not treat closures themselves as memory leaks.

## Files and requirements

The reports are stored in a private `pi-simplify-*` temporary directory with mode-0600 files. Failed or cancelled runs remove that directory. Successful runs retain it so the parent can read the reports; their paths appear in the handoff message and can be removed after the apply turn finishes.

The selected model must be available to a fresh Pi process. Four reviewers incur separate model usage in addition to the parent apply turn; their usage is not included in the parent's token and cost counters. `pi`, `rg`, and `fd` must be available on PATH. `jj` and `git` are optional and only used to decide whether to warn.

## Tests

Run from the repository root with Node 24+, Git, Jujutsu, and `pi` on `PATH`:

```sh
node --test config/pi/agent/extensions/simplify/simplify.test.ts
PI_E2E_MODEL=anthropic/claude-haiku-4-5 node --test config/pi/agent/extensions/simplify/simplify.e2e.test.ts
nix build .#checks.aarch64-darwin.pi-simplify
```

`simplify.test.ts` runs offline. Unit tests cover path parsing and validation, reviewer output parsing, the reviewer and apply prompts, version-control detection in real Git, Jujutsu, and plain directories, four concurrent reviewers with the inherited model and thinking level, each failure mode, ignored missing-model warnings, cancellation, and the command lifecycle: the warning only outside version control, busy and headless sessions, `/simplify cancel`, and silent shutdown. Their subprocess substitutes stay in the unit tests. The integration tests drive the actual `pi` CLI over RPC with an isolated agent directory, whose only model is a loopback endpoint that the reviewer subprocesses reach too. They run `/simplify` through the apply turn in a plain directory (with the warning), a Git repository with path arguments, and a Jujutsu repository (both without it), succeed when the settings name a model the catalog lacks, reject a missing path before any model request, stop when one reviewer's request fails, and cancel reviewers stuck on an unresponsive endpoint, checking that their connections close and no report directory remains.

`simplify.e2e.test.ts` runs `/simplify` through RPC with real reviewer subprocesses and a real model, using the credentials in your agent directory and the default model unless `PI_E2E_MODEL` names another. The fixture is a plain directory without version control where two call sites repeat what an existing `slugify` helper does. The parent must replace both with the helper, keep the fixture's behavior check passing, and not create a repository. It incurs model usage and runs separately from the sandboxed Nix check. A failed run keeps its fixture and RPC events for diagnosis.
