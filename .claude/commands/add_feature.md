---
description: Guided conversation to create a well-formed feature bead
allowed-tools: Bash(bd:*)
---

## Feature to add

$ARGUMENTS

---

## Your role

You are guiding the user through creating a well-formed feature bead. Your goal is to gather all the information needed to produce a bead that is clear, scoped, and ready to implement — or ready to be broken into child tasks.

---

## Process

### 1. Frame

If `$ARGUMENTS` is empty, ask the user to describe the feature in a sentence or two. Use their input as a starting point — don't ask again for things they've already told you.

### 2. Gather details through conversation

Work through the areas below. Ask focused questions in logical groups — don't dump everything at once. Wait for responses before moving on. Skip anything the user has already answered.

**Motivation and value**
- Why does this feature exist? What player problem does it solve, or what does it add to the gameplay loop?

**Player-facing behaviour**
- What does this look like from the player's perspective?
- How does a player trigger or interact with it?

**Acceptance criteria**
- What are the concrete, testable conditions that define "done"?

**Scope**
- What is explicitly *not* included in this feature?
- Are there related ideas that should be deferred to a separate bead?

**Design decisions**
- Are there any constraints or decisions already made that implementers should know about?

**Open questions**
- Are there unresolved decisions that should be captured and answered during implementation?

**Integration**
- What existing systems does this touch or depend on?

**Edge cases**
- Are there tricky scenarios worth capturing? (e.g. player is dead, inventory is full, no valid targets)

### 3. Assess size

Once the feature is well-understood, ask whether it's large enough to warrant child task beads. Features that span multiple layers (domain → server → CLI) typically should be broken up. If yes, identify the sub-tasks and gather titles and short descriptions for each.

### 4. Propose a title

Suggest a title following the naming convention:
- Describe what becomes possible from the player's perspective
- Use "Allow players to X" form, or a clear noun phrase describing the capability
- Confirm with the user before proceeding

Examples: *"Allow players to light and carry lanterns"*, *"Allow players to heal using a consumable item"*

### 5. Priority

Ask for priority if not already clear. Options: P0 (critical), P1 (high), P2 (medium — default), P3 (low), P4 (backlog).

### 6. Create the bead

Once all details are confirmed, create the feature bead:

```
bd create \
  --type=feature \
  --title="..." \
  --description="..." \
  --acceptance="..." \
  --design="..." \
  --notes="..." \
  --priority=N
```

Field guidance:
- `--description` — the motivation and player-facing behaviour
- `--acceptance` — the concrete done conditions
- `--design` — settled decisions and constraints
- `--notes` — open questions, edge cases, integration points, explicit out-of-scope items

If child tasks were identified, create them with `--parent <feature-id>` and wire up dependencies with `bd dep add` where one task genuinely can't start until another is complete.

### 7. Lint

Run `bd lint` and fix any issues before continuing.

### 8. Confirm

Report the created bead ID(s) and a brief summary of what was captured.
