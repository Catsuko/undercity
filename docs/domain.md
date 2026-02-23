# Undercity Domain Concepts

This document describes the core domain concepts in the Undercity codebase. It is intended for AI agents that need to understand the game's model without reading all source files.

---

## Overview

Undercity is a persistent, text-based multiplayer world. Players exist in the world at all times — there is no logout or disconnect concept. Connecting simply means waking up where you already are. Players navigate between named locations (blocks), search for items, carry an inventory, and can interact with the world by eating food, dropping items, and scribbling messages.

The codebase is split into three OTP applications:

- `undercity_core` — pure domain structs and logic, no OTP dependencies.
- `undercity_server` — OTP processes (GenServers) that manage runtime state and persistence.
- `undercity_cli` — command-line interface and game loop.

---

## Core Domain Concepts

### Block

**Definition:** A location (room) in the world where players can gather.

**Defined in:** `apps/undercity_core/lib/undercity_core/block.ex` (`UndercityCore.Block`)

**Key fields:**
```elixir
defstruct [:id, :name, :type, :scribble, people: MapSet.new(), exits: %{}]
```
- `id` — unique string identifier (e.g. `"plaza"`, `"wormgarden"`).
- `name` — human-readable display name (e.g. `"The Plaza"`).
- `type` — atom categorising the block: `:street | :square | :fountain | :graveyard | :space | :inn`. Determines the loot table used when searching.
- `people` — `MapSet` of player ID strings currently present at this block.
- `exits` — map of `direction => block_id`. Directions are `:north | :south | :east | :west | :enter | :exit`.
- `scribble` — optional string message written on the block by a player (max 80 alphanumeric characters, `nil` if none).

**Invariants:**
- A block tracks which players are present via `add_person/2` and `remove_person/2`.
- Only one scribble can exist on a block at a time; writing a new one overwrites the old one.

**Runtime process:** `UndercityServer.Block` (`apps/undercity_server/lib/undercity_server/block.ex`) is a GenServer wrapping `UndercityCore.Block`. One process per block, started statically at application boot. Persisted via `UndercityServer.Block.Store` (DETS file per block, at `data/blocks/<id>.dets`).

---

### Player

**Definition:** A character in the world, represented by a running GenServer process per connected player.

**Runtime process:** `UndercityServer.Player` (`apps/undercity_server/lib/undercity_server/player.ex`)

**Runtime state (map stored in process and DETS):**
```elixir
%{
  id: String.t(),            # hex string, 16 chars (8 random bytes, base16)
  name: String.t(),          # display name chosen at join
  inventory: Inventory.t(),
  action_points: ActionPoints.t(),
  health: Health.t()
}
```

**Key operations:**
- `Player.perform/3` — spends 1 AP (default) and runs an action function. Returns `{:ok, result, ap}` or `{:error, :exhausted}` or `{:error, :collapsed}`.
- `Player.add_item/2`, `drop_item/2`, `eat_item/2`, `check_inventory/1`, `use_item/3`.
- `Player.constitution/1` — returns `%{ap: integer, hp: integer}` representing current AP (after lazy regen) and HP.

**Invariants:**
- A player with `hp == 0` is collapsed and cannot spend AP or perform actions.
- Player processes are started dynamically by `UndercityServer.Player.Supervisor` (a `DynamicSupervisor`).
- State is saved to DETS after every mutating operation via `UndercityServer.Player.Store` (`data/players/players.dets`).
- A player's location is not stored on the player — it is inferred by which Block process lists them in its `people` set.

---

### AP (Action Points)

**Definition:** A resource pool that gates player actions. Each action costs at least 1 AP.

**Defined in:** `apps/undercity_core/lib/undercity_core/action_points.ex` (`UndercityCore.ActionPoints`)

**Key fields:**
```elixir
defstruct [:ap, :updated_at]
```
- `ap` — current action points (`non_neg_integer`).
- `updated_at` — Unix timestamp (seconds) of the last spend or regen event.

**Rules:**
- Maximum AP: `50` (compile-time default, configurable via `:action_points_max`).
- Regen rate: `1 AP per 1800 seconds` elapsed (configurable via `:action_points_regen_interval`).
- Regen is **lazy** — it is computed on demand by `ActionPoints.regenerate/2` when the player interacts with the server, not via a timer.
- Spending AP below zero fails with `{:error, :exhausted}`.
- AP is capped at `max()` on regeneration.
- A fresh player starts at max AP.

---

### Health

**Definition:** A player's hit points. Affects their ability to act.

**Defined in:** `apps/undercity_core/lib/undercity_core/health.ex` (`UndercityCore.Health`)

**Key fields:**
```elixir
defstruct [:hp]
```
- `hp` — current hit points (`non_neg_integer`).

**Rules:**
- Maximum HP: `50` (hard-coded constant, not configurable).
- Health starts at max on first creation.
- `apply_effect/2` accepts `{:heal, amount}` or `{:damage, amount}`. Result is clamped to `0..50`.
- At `hp == 0` the player is "collapsed" — they cannot perform any actions (`{:error, :collapsed}` is returned).
- There is currently no built-in HP regeneration mechanism.

---

### Inventory

**Definition:** The bounded collection of items a player carries.

**Defined in:** `apps/undercity_core/lib/undercity_core/inventory.ex` (`UndercityCore.Inventory`)

**Key fields:**
```elixir
defstruct items: []
```
- `items` — ordered list of `Item.t()`.

**Rules:**
- Maximum size: `15` items.
- `add_item/2` returns `{:error, :full}` when at capacity.
- Items are accessed by 0-based index.
- `find_item/2` searches by item name, returns `{:ok, item, index}` or `:not_found`.

---

### Item

**Definition:** An object that can be found and carried.

**Defined in:** `apps/undercity_core/lib/undercity_core/item.ex` (`UndercityCore.Item`)

**Key fields:**
```elixir
defstruct [:name, :uses]
```
- `name` — string identifier (e.g. `"Chalk"`, `"Mushroom"`, `"Junk"`).
- `uses` — `non_neg_integer | nil`. `nil` means non-consumable (infinite uses). A positive integer means the item has that many uses remaining.

**Rules:**
- `Item.use/1` decrements `uses`. Returns `{:ok, item}` with decremented count, or `:spent` when uses reach 0.
- Non-consumable items (`uses: nil`) always return `{:ok, item}` from `use/1`.

**Known items in the game:**
- `"Chalk"` — consumable, starts with 5 uses. Used to write scribbles on blocks. Found in squares (20% chance).
- `"Mushroom"` — edible, no uses field (consumed whole on eating). Found in graveyards (20% chance).
- `"Junk"` — non-edible, non-consumable. Found in most block types (10% default chance).

---

### Food

**Definition:** A mapping from item names to possible health effects when eaten.

**Defined in:** `apps/undercity_core/lib/undercity_core/food.ex` (`UndercityCore.Food`)

**How it works:**
- `Food.effect/1` takes an item name and returns a randomly selected effect tuple (e.g. `{:heal, 5}` or `{:damage, 5}`) or `:not_edible`.
- Currently only `"Mushroom"` is edible. Its outcomes are `[{:heal, 5}, {:damage, 5}]`, each equally likely (50/50).
- Eating removes the item from inventory and calls `Health.apply_effect/2` with the result.

---

### WorldMap

**Definition:** The static configuration of the world — all blocks and their connections.

**Defined in:** `apps/undercity_core/lib/undercity_core/world_map.ex` (`UndercityCore.WorldMap`)

**World layout (3x3 grid):**

```
ashwell        north_alley    wormgarden
west_street    plaza          east_street
the_stray      south_alley    lame_horse
```

Plus one interior block: `lame_horse_interior` (accessible via `:enter` from `lame_horse`).

**Block types:**
- `ashwell` — `:fountain`
- `north_alley`, `west_street`, `east_street`, `the_stray`, `south_alley` — `:street`
- `plaza` — `:square`
- `wormgarden` — `:graveyard`
- `lame_horse` — `:space`
- `lame_horse_interior` — `:inn`

**Key functions:**
- `WorldMap.spawn_block/0` — returns `"plaza"` (where new players appear).
- `WorldMap.resolve_exit/2` — resolves a `(block_id, direction)` pair to `{:ok, destination_id}` or `:error`.
- `WorldMap.surrounding/2` — returns a 3x3 grid of block IDs centred on the given block. Interior blocks inherit their parent's neighbourhood.
- `WorldMap.blocks/0` — returns all block definitions with computed exits as a list of maps.
- `WorldMap.building_type/1` — returns the type of the interior (`:inn`) if a block has an `:enter` exit, else `nil`.

**Invariants:**
- Connections are defined one-way; reverse exits are derived automatically at compile time.
- The `:enter`/`:exit` direction pair links outdoor blocks to interiors.
- All data is compile-time constants — no runtime mutations.

---

### LootTable

**Definition:** Probability tables mapping block types to items that can be found by searching.

**Defined in:** `apps/undercity_core/lib/undercity_core/loot_table.ex` (`UndercityCore.LootTable`)

**How it works:**
- Each entry is `{probability, item_spec}` where probability is a float and `item_spec` is either a name string or `{name, uses}` tuple.
- On a search, a random float `0.0..1.0` is rolled and checked cumulatively against each entry.
- Returns `{:found, Item.t()}` or `:nothing`.

**Tables:**
- `:square` — 20% chance of `{"Chalk", 5}`, then 5% chance of `"Junk"`.
- `:graveyard` — 20% chance of `"Mushroom"`.
- All other types — fall back to default: 10% chance of `"Junk"`.

---

### Vicinity

**Definition:** A snapshot of what a player perceives from their current location — the block they are in plus its neighbourhood.

**Defined in:** `apps/undercity_server/lib/undercity_server/vicinity.ex` (`UndercityServer.Vicinity`)

**Key fields:**
```elixir
defstruct [:id, :type, :people, :neighbourhood, :building_type, :scribble]
```
- `id` — block ID of the player's current location.
- `type` — block type atom.
- `people` — list of `%{id: String.t(), name: String.t()}` for all players present at this block.
- `neighbourhood` — 3x3 list of lists of block IDs (or `nil` for out-of-bounds cells), centred on the player's block.
- `building_type` — type of the interior accessible via `:enter`, or `nil` if no building here.
- `scribble` — the current scribble text on the block, or `nil`.

**How it is built:**
- `Vicinity.build/1` fetches live data from the running `Block` and `PlayerStore` processes.
- `Vicinity.new/3` constructs from known data (used in tests).

**Interior blocks:** `Vicinity.inside?/1` returns true when the player is in an interior block (one reachable via `:enter`). Interior blocks inherit their parent block's neighbourhood grid.

---

### Session

**Definition:** Manages the player connection lifecycle — entering the world and reconnecting.

**Defined in:** `apps/undercity_server/lib/undercity_server/session.ex` (`UndercityServer.Session`)

**How it works:**
- `Session.connect/1` (delegated via `Gateway`) connects to the server Erlang node and calls `enter/1`.
- `Session.enter/1` checks `PlayerStore` by name. If the player exists, reconnects them to the block they were last in. If new, generates a player ID (16-char hex string), starts a Player process, saves to store, and joins them to `"plaza"` (spawn block).
- Returns `{player_id, vicinity, constitution}` on success.
- Connection retries with exponential backoff (up to 5 attempts).

**Invariants:**
- Player names are looked up case-sensitively by exact match.
- A player's current block is determined at reconnect by scanning all blocks for presence — not stored on the player record.

---

### Gateway

**Definition:** The single public API surface for client code to interact with the game server.

**Defined in:** `apps/undercity_server/lib/undercity_server/gateway.ex` (`UndercityServer.Gateway`)

**Delegates to:**
- `Session` — `connect/1`, `enter/1`
- `Player` — `check_inventory/1`, `drop_item/2`
- `Actions.Movement` — `perform(player_id, block_id, :move, direction)`
- `Actions.Search` — `perform(player_id, block_id, :search, _)`
- `Actions.Scribble` — `perform(player_id, block_id, :scribble, text)`
- `Actions.Eat` — `perform(player_id, _, :eat, index)`

---

## Actions

All player actions that cost AP go through `Player.perform/3`, which: (1) checks the player is not collapsed, (2) applies lazy AP regen, (3) spends the cost, and (4) executes the action function.

| Action | Module | AP Cost | Effect |
|---|---|---|---|
| Move | `Actions.Movement` | 1 | Leave current block, join destination block, return new `Vicinity` |
| Search | `Actions.Search` | 1 | Roll loot table for block type; add found item to inventory |
| Scribble | `Actions.Scribble` | 1 | Sanitise text, consume 1 use of Chalk, write text to block |
| Drop | `Player.drop_item/2` | 1 | Remove item from inventory by index |
| Eat | `Actions.Eat` / `Player.eat_item/2` | 1 | Remove edible item, apply health effect |

**Common error returns:**
- `{:error, :exhausted}` — player has 0 AP.
- `{:error, :collapsed}` — player has 0 HP.
- `{:error, :no_exit}` — no exit in requested direction.
- `{:error, :full}` — inventory is at capacity (15 items).
- `{:error, :item_missing}` — named item not in inventory.
- `{:error, :not_edible, item_name}` — item cannot be eaten.

---

## Persistence

- **Player state** — single DETS file: `data/players/players.dets`. Keyed by player ID string.
- **Block state** — one DETS file per block: `data/blocks/<block_id>.dets`. Stores current `UndercityCore.Block` struct (including which players are present and the scribble).
- State is saved synchronously after every mutating operation.
- On server restart, block and player processes reload from their DETS files.

---

## Process Architecture

```
UndercityServer.Supervisor (one_for_one)
  UndercityServer.Player.Store          (single DETS-backed GenServer for all players)
  UndercityServer.Player.Supervisor     (DynamicSupervisor; one child per connected player)
    UndercityServer.Player              (GenServer per player — started on connect)
  UndercityServer.Block.Supervisor      (one per block, rest_for_one)
    UndercityServer.Block.Store         (DETS-backed GenServer per block)
    UndercityServer.Block               (GenServer per block — started at boot)
```

- Block processes are **static** — started at boot for every block in `WorldMap`.
- Player processes are **dynamic** — started when a player connects, persist while the server is running.
- The server runs on a named Erlang node (`undercity_server@127.0.0.1`); the CLI connects to it as a distributed node.

---

## Key Relationships

- A **Player** is located at a **Block** — tracked by the Block's `people` MapSet (player IDs).
- **Blocks** form the **WorldMap** — a fixed 3x3 grid plus interior blocks; all connections are compile-time.
- A **Vicinity** is a runtime view combining the player's current Block, its neighbourhood grid, and present players' names.
- A **Player** carries an **Inventory** of **Items**.
- **LootTable** is keyed by **Block type** — searching a block uses the table for that type.
- **Food** maps **Item** names to health effects applied via **Health**.
- **ActionPoints** gate all actions; **Health** at 0 gates all actions too.
