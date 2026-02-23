# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Task Tracking

Use 'bd' for task tracking.

## Environment

- On Windows (MSYS2/Git Bash), use `mix.bat` and `elixir.bat` instead of `mix` and `elixir`. The extensionless POSIX shell scripts don't work correctly in this environment.

## Branching

- Branch naming: `{bead-id}-{descriptor}`, e.g. `67e-branching-convention`
- Always branch from `main` unless specified otherwise
- One branch per bead; sub-tasks use the parent bead's branch unless specified otherwise
- Merges are handled manually (not by Claude)

## Code Quality

- Use `mix lint` for linting (runs `mix format --check-formatted` and `mix credo --strict`).
- Before committing, run tests (`mix test`) and linting (`mix lint`) to ensure nothing is broken.

## Content

- Refer to `STYLE_GUIDE.md` when writing or reviewing world content (block descriptions, flavour text, etc.).

## Workflow

- When starting a bead, work through design questions and concerns one by one with the user before moving to implementation.
- When exploring or investigating, start with `docs/architecture.md` for a system overview, then check other files in `docs/` for topic-specific detail (actions, persistence, testing, domain). Per-app conventions and process structure are documented in the `@moduledoc` of each top-level module (`UndercityCore`, `UndercityServer`, `UndercityCli`).
- Always ask for review before closing/completing tasks or committing to git, unless explicitly told otherwise.
