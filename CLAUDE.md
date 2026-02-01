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

## Workflow

- Always ask for review before closing/completing tasks or committing to git, unless explicitly told otherwise.
