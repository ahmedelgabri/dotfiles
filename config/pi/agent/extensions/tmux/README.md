# tmux extension

`index.ts` registers the `tmux` tool for starting, reading, controlling,
listing, and stopping named worker panes. It loads only when Pi runs inside tmux
and skips herdr environments.

## Layout

When no managed workers exist, a `right` worker splits Pi's pane horizontally
and a `bottom` worker splits it vertically. Later right workers split the
tallest managed worker vertically, which keeps Pi's width fixed and distributes
worker height instead of repeatedly halving one pane. Later bottom workers split
the widest managed worker horizontally. Unmanaged panes do not become part of
the worker layout.

Pane layout mutations run through one in-process queue because tool calls from
one assistant message may execute concurrently. A failed mutation does not block
later operations.

A split is rejected before tmux runs when either resulting pane would have fewer
than 20 columns or 3 rows. The existing layout stays unchanged when this check
fails.

## Validation

Run the type check and the real-tmux regression suite from the repository root
with Node.js 24 or later and tmux installed. The suite uses `node:test`, strict
assertions, and Node child processes, with no Bun dependency.

```sh
tsc -p config/pi/agent/extensions/tsconfig.json
node --test config/pi/agent/extensions/tmux/layout.test.ts
```

The suite covers split planning, unmanaged panes, queue recovery after errors,
sequential layouts, capacity rejection, and seven concurrent right-positioned
workers in a detached tmux session.
