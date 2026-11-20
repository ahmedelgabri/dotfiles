# Agent skills

Skills shared by every agent harness live in [skills/](./skills/). Home Manager
links them into `~/.agents/skills`, which Pi and Codex read on their own, and
into `~/.claude/skills`, because Claude Code does not read `~/.agents/skills`.

The `rex` skill is not checked in. Install it from the Rex app with `rex skill setup`, which writes it to `~/.agents/skills/rex` and `~/.claude/skills/rex`. Its `SessionStart` hooks are already in `config/claude/settings.json` and `config/codex/hooks.json`, with session naming off, so setup only adds the skill. Pi has no command hooks; the [`rex-session-start`](../pi/agent/extensions/rex-session-start/README.md) pi extension adds the same context.

A skill that only one harness should see goes in that harness's `skills`
directory instead:

| Source                 | Target                                                      |
| ---------------------- | ----------------------------------------------------------- |
| `config/agents/skills` | `~/.agents/skills`, `~/.claude/skills`                      |
| `config/claude/skills` | `~/.claude/skills`                                          |
| `config/pi/skills`     | `~/.config/pi/agent/skills` (`$PI_CODING_AGENT_DIR/skills`) |
| `config/codex/skills`  | `~/.config/codex/skills` (`$CODEX_HOME/skills`)             |

Each file is a separate symlink into the checkout, so edits apply without a
rebuild, but new or removed files need one. A harness directory may be missing;
Git does not track empty directories, and the Nix module skips any that do not
exist.

When a harness skill and a shared skill have the same name, the harness files
win path by path. Files that exist only in the shared copy still get linked, so
give a harness-only skill its own name unless you mean to override specific
files.

To add a harness, add an entry to `skillTrees` in
[nix/parts/modules/shared/ai.nix](../../nix/parts/modules/shared/ai.nix) with
its source directory and target paths. If the harness does not read
`~/.agents/skills`, also add its skills path to the `targets` of the
`agents/skills` entry.

Machine-specific Pi skills go in `$HOST_CONFIGS/pi/skills`; see the main
[README](../../README.md#machine-local-configuration).
