# Code Documentation Styleguide

This guide defines conventions for `@moduledoc` and `@doc` in Undercity. Documentation is written for two audiences: human contributors and LLM agents. Both benefit from the same things: concise summaries, explicit semantics, and structured formatting over prose.

These conventions are enforced by `mix doctor` via `mix lint`.

---

## Principles

- **First sentence is the summary.** It must be self-contained — it will be read in isolation in search results, hover text, and summarised context.
- **Bullets over prose.** Lists parse more reliably than paragraphs when extracting structured meaning.
- **Explicit over implicit.** State what happens, not what might be inferred.
- **Context window economics.** Keep docs short. Every token counts when this code is used as LLM context.
- **Concrete over abstract.** Name the actual values, atoms, and structs involved.

---

## `@moduledoc`

The module doc describes the module's role in the system. It should answer: *what does this module do, and what is it responsible for?*

**Structure:**

```
One-sentence summary of the module's role.

- Key responsibility one
- Key responsibility two
- Key responsibility three
```

**Rules:**

- First sentence: what the module does and its place in the system. One line.
- Bullet list: specific responsibilities. Aim for 2–5 bullets.
- Omit anything obvious from the module name.
- Do not describe implementation details — describe behaviour and contracts.
- Use `@moduledoc false` only for modules that are intentionally private and should not appear in generated docs (e.g. internal helpers with no public API). This still satisfies the doc requirement.

**Example:**

```elixir
@moduledoc """
Resolves combat actions between players and blocks, applying damage and returning updated state.

- Validates the action is legal given current AP and target state
- Calculates damage using the active weapon's stats
- Returns updated player and block structs without side effects
"""
```

---

## `@doc`

The function doc describes what a function does, when to use it, and what to expect back.

**Structure:**

```
One-sentence summary in imperative form.

- Param or behaviour note (if not obvious)
- Return value semantics (when @spec is absent or needs elaboration)
- Side effects (if any)
```

**Rules:**

- First sentence: imperative verb phrase. "Applies…", "Returns…", "Dispatches…", "Registers…"
- Only add bullets if there is something to say beyond the summary. Do not pad.
- **If `@spec` is present:** do not repeat the types. Focus on semantic meaning — what do the return values *mean*, when does each branch occur.
- **If `@spec` is absent:** include the shape and semantics. e.g. `Returns {:ok, pid} on success, {:error, :already_started} if the player session exists.`
- Always document side effects explicitly: process sends, state mutations, DB writes.
- Use `@doc false` for public functions that are not part of the intended API (e.g. OTP callbacks). This satisfies the doc requirement.

**Example — with `@spec`:**

```elixir
@spec heal(Player.t(), integer()) :: {:ok, non_neg_integer(), Player.t()} | {:error, :at_max_hp}
@doc """
Applies healing to a player, capped at their maximum HP.

- Returns `{:ok, healed, updated_player}`
  - `healed` may be 0 if already at max
- Returns `{:error, :at_max_hp}` if the player is already at full health.
- Does not persist the result — caller is responsible for broadcasting the update.
"""
def heal(player, amount) do
```

**Example — without `@spec`:**

```elixir
@doc """
Registers a player session under the given player ID.

- `player_id` must be a non-empty string.
- Returns `{:ok, pid}` with the session GenServer PID on success.
- Returns `{:error, :already_started}` if a session for this player already exists.
- Side effect: broadcasts a `:player_connected` event to the district PubSub topic.
"""
def start_session(player_id) do
```

---

## What not to document

- Implementation details that are visible from reading the code.
- Obvious parameters (e.g. don't say "`name` is the name").
- Return values already fully described by a clear `@spec` with no ambiguity.
- Changelog or history notes — that belongs in git.
