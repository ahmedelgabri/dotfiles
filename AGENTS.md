# AGENTS.md

This is a Nix-flake-powered personal dotfiles repo for macOS (Apple Silicon) and
experimental NixOS. It manages system configuration, packages, shell, editor,
terminal, mail, and development tooling.

This repository uses the Jujutsu version control system (see the `/jujutsu`
skill for details).

## How things work

Hosts are defined in `nix/parts/hosts/`. Each host declares a list of features
(e.g. `shell`, `git`, `vim`, `mail`, `ai`) and the flake wires in matching
system and Home Manager modules from `nix/parts/modules/`.

Application configs in `config/` are checked into the repo and symlinked into
place by Home Manager.

## Key conventions

- Smallest reasonable changes. Do not refactor unrelated code.
- Match the style of surrounding code even if it differs from standard guides.
- Do not remove code comments unless they are provably false.
- Do not add temporal references in comments (e.g. "recently added").
- No trailing whitespace, including on blank lines.
- Comments should describe "why", not "what".

## Version control

This repo uses [Jujutsu](https://jj-vcs.github.io/) (`jj`) instead of `git` for
version control. Commit frequently and make small, focused commits.

### Commit message format

Use [Conventional Commits](https://www.conventionalcommits.org/) formatting:

- Start the subject line with a type prefix: `docs:`, `fix:`, `chore:`, `test:`,
  `refactor:`, `feat:`, etc.
- Optionally scope the prefix (e.g., `refactor(nix):`, `fix(neovim):`); if the
  changes affect a single aspect, use the aspect name as the scope.
- The rest of the subject line should start with a verb in the imperative form;
  ie. "add", "teach", "fix" etc.
- Keep subject lines under 72 columns.
- In the commit body, hard-wrap to 80 columns.
- Use Markdown formatting for _bold_, _italics_, `code`, and fenced code blocks.
- Describe _what_ changed as concisely as possible; fit it in the subject if you
  can, but feel free to continue concisely in the body if fitting it all in the
  subject is not possible.
- Use the body to explain the motivation for the change was made and why the
  particular approach was chosen; you should include info on the alternatives
  considered, and why they were not chosen.

## Markdown

When writing Markdown, do not hard-wrap long lines.

## Secrets

Truly sensitive credentials live in `pass`. `agenix` is used only for lower-risk
private files that should stay out of the public repo. Never commit secrets or
tokens.

H2 Update docs

Whenever you make a change make sure to update all relevant docs if needed
(`README.md`, etc...)
