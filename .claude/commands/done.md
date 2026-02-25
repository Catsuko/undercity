---
description: Test, lint, commit, push, close bead, and summarise PR
allowed-tools: Bash(mix.bat:*), Bash(git:*), Bash(bd:*)
---

## Context

- Current branch: !`git branch --show-current`
- Git status: !`git status`
- Git diff (staged and unstaged): !`git diff HEAD`
- Recent commits (for message style reference): !`git log --oneline -5`
- Active bead: !`bd list --status=in_progress`

## Your task

Execute the session-close pipeline in order. Stop and report clearly if any step fails — do not proceed past a failure.

### Step 1: Test and lint

Run tests and linting:

```
mix.bat test
mix.bat lint
```

If either fails, stop immediately and report the full failure output. Do not continue.

### Step 2: Commit

Stage all changes and create a single commit. Generate the commit message based on the diff, following the style of recent commits in the repo.

### Step 3: Push

Push the current branch to origin.

### Step 4: Close the active bead

The branch follows the `{bead-id}-{descriptor}` naming convention (e.g. `bus-done-skill` → bead ID `bus`). Extract the bead ID from the current branch name and close it with `bd close {bead-id}`.

If the branch is `main` or does not match the convention, skip this step and note it.

### Step 5: Generate PR summary

Generate a PR title and summary based on the branch name and the commits on this branch vs main. Output it for the user in this format:

```
PR Title: <title>

PR Summary:
<body>
```

Do not create the PR — just output the title and summary.

---

On success, report each completed step. On failure, report which step failed and why.
