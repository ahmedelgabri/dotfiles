# Headless mode

Runs without a UI have nobody to answer questions: `pi -p`, `pi --mode json`,
[`/loop`](../loop/README.md) iterations, and
[`/simplify`](../simplify/README.md) reviewers. An agent that asks one anyway
ends the run with a question instead of a result. When `ctx.hasUI` is false,
this extension adds a `<headless>` section to the system prompt that tells the
agent to make and state reasonable assumptions, skip offers and requests for
input, report what it did, and explain any blocker in its final response. There
are no commands or settings.

Interactive and RPC sessions are unchanged, because an RPC client can answer
through its own UI. `/loop` already gives its children a similar instruction, so
they receive both.

The section goes through `systemPromptOptions.sections` instead of a returned
`systemPrompt`. A returned prompt replaces the whole prompt and drops sections
and guidelines that extensions running later add, such as the
[jujutsu](../jujutsu/README.md) guideline.
