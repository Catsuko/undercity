---
description: Survey the Undercity codebase for linear growth patterns and flag areas of potential future maintainability concern
allowed-tools: Bash(git log:*), Bash(git rev-list:*), Bash(wc:*), Glob, Grep, Read
---

## Your role

You are an architectural health checker. Your job is to identify files in the production source that show signs of linear, unbounded growth — and present a short, curated shortlist to the user with enough evidence to understand the pattern.

**You do not propose solutions, refactors, or recommendations at this stage.** Diagnosis only.

---

## Scope

Analyse files in `apps/*/lib/**` only. Exclude tests, config, docs, and mix files.

---

## Phase 1: Cheap curation — file metrics

Use Glob to list all `.ex` files under `apps/*/lib/`:

```
apps/*/lib/**/*.ex
```

For each file, gather two cheap signals without touching git:

**Line count:**
```bash
wc -l <file>
```

**Public function count:**
Use Grep to count lines matching `^\s+def ` in the file. This counts Elixir public function definitions — the structural signal of a module accumulating responsibilities.

Score each file by combining these two signals (e.g. weight def count more heavily, since a medium-sized file with many public functions is more concerning than a large file with few). Take the **top 10 suspects** by score. These are your candidates for further investigation.

---

## Phase 2: Churn check — recency and activity

For each of the 10 suspects, gather two cheap git signals:

**Last touched:**
```bash
git log -1 --format="%ci" -- <file>
```

**Recency count** — how many of the last 20 repository commits touched this file:
```bash
git log --oneline -20 -- <file>
```

Apply these filters:

- **Dormant files** (not touched in the last 30 repository commits) — exclude unless all other signals are extreme
- **Low recency** (recency count of 0–1 in last 20) — deprioritise; size alone is not a concern if the file is stable

Score remaining suspects by combining recency count with their Phase 1 score. Retain the **top 3–5** as your final candidates.

---

## Phase 3: Deep history — growth pattern and commit themes

For each final candidate, run a thorough git history inspection:

**Full numstat history:**
```bash
git log --numstat --follow -- <file>
```

Extract:
- **Total lines added** and **total lines deleted** over the file's lifetime
- **Add:delete ratio** = total added / (total deleted + 1). High ratio = accumulation; balanced ratio = evolution and rework.
- **Net line growth** = total added − total deleted

**Commit messages:**
```bash
git log --follow --pretty=format:"%s" -- <file>
```

Read the commit messages and identify **what kinds of tasks keep driving changes** to this file. Are changes consistently adding new actions, new callbacks, new features of a single type? That pattern is the growth story.

---

## Output

For each flagged file, present:

```
**apps/<app>/lib/<path>.ex**
<line_count> lines · <def_count> public functions · touched in <recency_count> of last 20 commits
Lifetime: net +<net_lines> lines (add:delete ratio <X>:<Y>)
Growth pattern: <1–2 sentences describing what the commit history reveals — what kinds of changes keep happening, and whether growth is accelerating or steady>
```

After presenting all flagged files, ask the user which file(s) they would like to explore in more detail, and wait for their response.

---

## Principles

- **Short list, not an audit.** 3–5 files maximum. Curate, don't enumerate.
- **Diagnosis only.** Do not suggest solutions, refactors, or next steps at this stage.
- **Dormant files are noise.** Size without recent activity is not a concern.
- **Public function count is the structural signal.** A medium file with many public functions is more concerning than a large file with few.
- **Commit messages tell the story.** Raw numbers show that growth is happening; commit themes explain *why* — and why it will continue.
