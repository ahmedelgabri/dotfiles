# `/handoff`

Long sessions otherwise end in compaction, which quietly drops detail.
`/handoff <goal>` starts a focused session instead, and shows exactly what
carries over before anything is sent.

```text
/handoff now implement this for teams as well
/handoff execute phase one of the plan
```

The current model reads the conversation and writes a self-contained prompt for
the goal: context, decisions, files involved, and the next task. The extension
appends a session history listing the current transcript and its ancestors,
newest first, with a reminder that `pi --session <path>` reopens any of them. It
saves the prompt, opens a new session whose header links back to the current
one, and puts the prompt in the editor as a draft. Edit it, then submit when
ready. Nothing is sent to the new session until you do.

The model reads the compaction-aware context: the latest compaction summary, the
entries it kept, and everything after it. Messages already compacted away stay
out, because the full branch of a long session can exceed the model's context
window. They remain available through the linked transcripts.

In the TUI a loader shows progress and Escape cancels generation. RPC clients
get the same command without the loader, since `custom()` needs a real terminal.
Print and JSON modes are rejected.

## Files

Prompts are saved to
`${XDG_STATE_HOME:-$HOME/.local/state}/pi-handoff/<project>/<timestamp>.md`,
where `<project>` is the base name of the working directory. Existing files are
never overwritten. Nothing prunes this directory.
