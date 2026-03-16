---
description: Guided conversation to create a well-formed bug bead
allowed-tools: Bash(bd:*)
---

## Bug to report

$ARGUMENTS

---

## Your role

You are guiding the user through creating a well-formed bug bead. Your goal is to gather all the information needed to produce a bead that is reproducible, clearly scoped, and gives the implementer enough context to fix it confidently.

---

## Process

### 1. Frame

If `$ARGUMENTS` is empty, ask the user to describe the bug in a sentence or two. Use their input as a starting point — don't ask again for things they've already told you.

### 2. Gather details through conversation

Work through the areas below. Ask focused questions in logical groups — don't dump everything at once. Wait for responses before moving on. Skip anything the user has already answered.

**Reproduction**
- What are the exact steps to trigger this bug reliably?
- Reproducibility is the most critical thing to capture — a bug you can't reproduce can't be confidently fixed.

**Expected vs actual**
- What *should* happen?
- What *does* happen? (describe the symptom precisely)

**Context**
- Under what conditions does it occur? (specific game state, command sequence, edge case)
- Does it happen every time, or only sometimes?

**Root cause**
- Is the underlying reason known or suspected? (keep this separate from the symptom)

**Impact**
- How often does this occur?
- Who or what is affected?
- How severe is it — does it break gameplay, cause data loss, just look wrong?

**Proposed fix**
- Any initial thinking on how to correct it, even if speculative?

**Regression**
- How was this likely introduced?
- What should the fix be careful not to break?

**Code locations**
- Are there specific files or functions known to be involved?

### 3. Propose a title

Suggest a title following the naming convention:
- Describe the symptom, not the cause
- Use "[Thing] breaks/fails/errors when [condition]" form

Examples: *"UI breaks when message log overflows panel"*, *"Attack command fails silently when target is in a different block"*

Confirm with the user before proceeding.

### 4. Priority

Ask for priority if not already clear. Options: P0 (critical), P1 (high), P2 (medium — default), P3 (low), P4 (backlog).

### 5. Create the bead

Once all details are confirmed, create the bug bead:

```
bd create \
  --type=bug \
  --title="..." \
  --description="..." \
  --notes="..." \
  --priority=N
```

Field guidance:
- `--description` — steps to reproduce, expected behaviour, actual behaviour, context
- `--notes` — root cause, impact, proposed fix, regression concerns, related code locations

### 6. Lint

Run `bd lint` and fix any issues before continuing.

### 7. Confirm

Report the created bead ID and a brief summary of what was captured.
