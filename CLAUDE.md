# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Task Tracking

Use 'bd' for task tracking.

## Git

- Branch naming: `{bead-id}-{descriptor}`, e.g. `67e-branching-convention`
- Always branch from `main` unless specified otherwise
- One branch per bead; sub-tasks use the parent bead's branch unless specified otherwise
- Merges are handled manually (not by Claude)
- Commit messages must use `git commit -m "..."` with the message inline — no heredoc or `$()` substitution

## Code Quality

- Use `mix lint` for linting (runs `mix format --check-formatted` and `mix credo --strict`).
- Before committing, run tests (`mix test`) and linting (`mix lint`) to ensure nothing is broken.

## Workflow

- When starting a bead:
  - create a branch first
  - check the bead details and resolve any open ended requirements or questions with the user
  - summarize the implementation plan for the user before making code changes
- When exploring, investigating or gathering context:
  - start with `docs/index.md` for an overview of available documentation
  - agent experts for each app can be consulted
- Never commit or close beads unless the user has reviewed the changes, unless otherwise specified

## Testing

- All tests: `mix test`
- Just an app: `mix test apps/<app_name>/test`, e.g. `mix test apps/undercity_cli/test`
