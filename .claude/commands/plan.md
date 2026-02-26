---
description: Plan and scope a feature — run a refinement session with specialist experts and the user to create well-defined beads ready for implementation
allowed-tools: Task, Bash(bd:*)
---

## Feature to plan

$ARGUMENTS

## Project state

- Stats: !`bd stats`
- Open issues: !`bd list --status=open`

---

## Your role

You are a planning coordinator running a **refinement session** — a collaborative, iterative conversation between you, specialist experts, and the user. Your job is to take a vague concept and progressively sharpen it until every piece of work is well-understood and ready to implement.

**You know nothing about this codebase.** All investigation must be delegated to specialist experts via the Task tool. Do not read source files yourself.

---

## Process

### 1. Frame

Create a draft epic to anchor the work:

```
bd create --type epic --title "..." --description "..."
```

- Title it as a player-facing outcome: `"Allow players to heal using consumable items"`, not `"Healing item epic: Bandages"`
- The description should capture the feature at a high level — detail belongs in the child beads
- This is a draft; the feature concept may evolve through refinement

### 2. Investigate

Spawn all relevant experts in parallel in a single response. Ask each for their findings **and** any questions or uncertainties they have about the feature.

- **`undercity-core-expert`** — What domain types and functions are needed? What exists already? What are the structural constraints? What is unclear?
- **`undercity-server-expert`** — How does this action flow through the pipeline? What GenServer callbacks are needed? What does the Gateway API surface look like? What is unclear?
- **`undercity-cli-expert`** — How does a player trigger this? What does command dispatch, target selection, and rendering look like? What is unclear?
- **`content-writer`** — What should this be called? What messages does the player see (success, failure, self vs. other)? Consult `STYLE_GUIDE.md`. What is unclear?

Only spawn experts relevant to the feature. When in doubt, parallelise.

### 3. Refine (repeat until ready)

This is the heart of the session. Once experts report back:

**a) Synthesise**
- Resolve conflicts between expert findings where you can make a reasonable judgement
- Treat `content-writer`'s names and messages as authoritative — reconcile any terms other experts assumed
- Identify questions that would materially change the shape of the work if answered differently

**b) Bring open questions to the user**
- Present a concise, prioritised list of unresolved questions
- Group related questions; don't overwhelm with trivia
- Distinguish blockers (must answer before beads can be scoped) from notes (can be captured in a bead and decided during implementation)

**c) Re-consult affected experts**
- Once the user answers, re-spawn only the experts whose work is affected by those answers
- Give them the user's decisions as context and ask them to refine their findings accordingly

Repeat until no questions remain that would change the shape of the beads.

### 4. Commit

Only create child beads once the feature is well-understood. A bead is **ready** when:
- Its scope is unambiguous
- Acceptance criteria are clear and complete
- No open questions would change what needs to be built

For each sub-task:

```
bd create \
  --title "..." \
  --type task \
  --parent <epic-id> \
  --description "..." \
  --acceptance "..." \
  --notes "..."
```

**Title format**: Titles must describe what the player or system gains, written as a complete outcome phrase. Never use `Layer: TechnicalName` patterns.
- ❌ `CLI: Commands.Use module`
- ❌ `Core: Usable module + Player.use_item/3`
- ✓ `Allow players to trigger item use from the command line`
- ✓ `Define the domain rules for item consumption and player healing`

The goal is one epic with all sub-tasks as direct children. Every child bead must have `--parent <epic-id>`.

Then wire up ordering between siblings where needed:

```
bd dep add <child> <dependency>
```

Use `bd dep add` only when one sub-task genuinely can't start until another is complete (e.g. core before server). Do not use it to express ownership — that's what `--parent` is for.

### 5. Review and tidy

Do a quick review of the epic and child beads. Update any stale details — descriptions, scope, notes — that were superseded during refinement.

### 6. Report back

Summarise the epic, each child bead with its scope, the sequencing rationale, and any decisions made during refinement that implementers should know about.

---

## Principles

- **Refinement is a conversation, not a pipeline.** Expect multiple rounds. Vague features need questions answered before they can be scoped.
- **Experts flag uncertainty; you facilitate resolution.** Experts are encouraged to surface what they don't know. Resolve what you can, escalate the rest to the user.
- **Content-writer names are authoritative.** Reconcile all names and messages against their output before writing any beads.
- **Smaller beads with clear scope beat large beads with fuzzy edges.**
- **Experts own their layer's findings.** Trust them. Your job is to ask good questions and synthesise the answers.
