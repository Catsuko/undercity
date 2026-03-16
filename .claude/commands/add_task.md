---
description: Guided conversation to create a well-formed task bead
allowed-tools: Bash(bd:*)
---

## Task to add

$ARGUMENTS

---

## Your role

You are guiding the user through creating a well-formed task bead. Your goal is to gather all the information needed to produce a bead that is technically precise, clearly motivated, and unambiguous about what "done" means.

---

## Process

### 1. Frame

If `$ARGUMENTS` is empty, ask the user to describe the task in a sentence or two. Use their input as a starting point — don't ask again for things they've already told you.

### 2. Gather details through conversation

Work through the areas below. Ask focused questions in logical groups — don't dump everything at once. Wait for responses before moving on. Skip anything the user has already answered.

**The work**
- What exactly needs to be done? (technical description — be specific)

**Motivation**
- Why is this needed? (enables a feature, fixes fragility, reduces duplication, prerequisite for something else?)
- This is the most important thing to capture — without it, implementers make wrong tradeoffs.

**Definition of done**
- How will you know it's complete? What does the finished state look like?

**Scope**
- What files, modules, or layers does this touch?
- What is explicitly out of scope?

**Approach and constraints**
- Are there any decisions already made about *how* to do it?
- Are there any constraints on the implementation approach?

**Preservation**
- Is there existing behaviour that must be preserved? (especially important for refactors)

**Risks**
- Are there places where this change could introduce subtle breakage?

**Parent feature**
- Does this task implement part of a feature bead? If so, which one?
- Ask the user if unsure — tasks that belong to a feature should be linked as children.

### 3. Propose a title

Suggest a title following the naming convention:
- Imperative action phrase describing the technical work
- Should be self-explanatory without needing context

Examples: *"Consolidate AP-gating into a single authoritative pattern"*, *"Make BlockDescription resilient to new block types"*

Confirm with the user before proceeding.

### 4. Priority

Ask for priority if not already clear. Options: P0 (critical), P1 (high), P2 (medium — default), P3 (low), P4 (backlog).

### 5. Create the bead

Once all details are confirmed, create the task bead:

```
bd create \
  --type=task \
  --title="..." \
  --description="..." \
  --acceptance="..." \
  --notes="..." \
  --priority=N \
  [--parent=<feature-id>]
```

Field guidance:
- `--description` — the motivation and what needs to be done
- `--acceptance` — the definition of done
- `--notes` — scope, approach, constraints, what must not change, risks

Include `--parent` if this task belongs to a feature bead.

### 6. Lint

Run `bd lint` and fix any issues before continuing.

### 7. Confirm

Report the created bead ID and a brief summary of what was captured.
