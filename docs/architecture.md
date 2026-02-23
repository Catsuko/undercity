# Undercity Architecture

Undercity is a persistent, text-based multiplayer game. Players exist in the world at all times — connecting means waking up where you left off. The codebase is an Elixir umbrella with three apps in a linear dependency chain:

```
undercity_cli → undercity_server → undercity_core
```

## Three Apps

**`undercity_core`** — Pure domain logic: structs and functions only, no OTP, no processes. Defines the world model (blocks, items, inventory, AP, health, loot tables). The rest of the system builds on this.

**`undercity_server`** — The game server. Runs as a named Erlang node (`undercity_server@127.0.0.1`). Owns all OTP processes: one GenServer per block (static, started at boot), one GenServer per connected player (dynamic), plus a shared player store. Exposes a `Gateway` module as the single public API surface. Persists all state to DETS files.

**`undercity_cli`** — The client. No OTP application — no processes at boot. Connects to the server via distributed Erlang, then runs a recursive game loop that reads input, dispatches commands through `Gateway`, and renders the terminal view.

For per-app detail, see the `@moduledoc` on `UndercityCore`, `UndercityServer`, and `UndercityCli`.

## Key Design Decisions

**Distributed Erlang for client-server**: The server runs as a named node (`undercity_server@127.0.0.1`); the CLI starts its own short-lived named node and connects to it. Once connected, the CLI calls `Gateway` functions via distributed Erlang transparently — no explicit RPC boilerplate, just regular function calls that cross the node boundary. The two processes must be started separately (`mix undercity.server` then `mix undercity.join`).

**CLI knows nothing about core**: Despite the umbrella dependency allowing it, `undercity_cli` intentionally does not reference `undercity_core` types directly. All interaction goes through `Gateway` and the types it exposes (e.g. `Vicinity`). This keeps the client decoupled from domain internals.

**Pure core, stateful server**: `undercity_core` has no side effects — all runtime state lives in `undercity_server` GenServers. This makes the domain logic easy to test and reason about in isolation.

**Lazy AP regeneration**: Action points regen over time but are calculated on demand when the player acts, not via timers. The struct stores the last-updated timestamp and computes elapsed regen on access.

**Location tracked by blocks, not players**: A player's current location isn't stored on the player record. Instead, blocks maintain a set of present player IDs. Reconnecting players are located by scanning blocks.

## Supervision Tree

Block supervisors are static `:rest_for_one` pairs (Store → Block), one per world block, started at boot. The player supervisor is a `DynamicSupervisor` — player processes are started on demand when a player connects and persist for the lifetime of the server.

## World Model

The world is a fixed 3×3 grid of blocks plus interior blocks reachable via `:enter`/`:exit` exits. Block connections are defined once as directed edges in `WorldMap` at compile time; reverse exits are derived automatically. Spawn block is `plaza`.

Each block has a type (`:street`, `:square`, `:graveyard`, etc.) which determines its loot table when players search.

## Request Lifecycle

All player actions go through `Gateway.perform/4`, which RPC's to the server node. On the server, AP-costing actions go through `Player.perform/3`, which: checks the player isn't collapsed, applies lazy AP regen, spends the AP cost, then runs the action. Block mutations (join/leave/scribble/search) call into the relevant `Block` GenServer.

## Persistence

All state is stored in DETS (Erlang disk-based term storage). Players share a single DETS table; each block has its own file. State is written synchronously after every mutating call. On restart, processes reload from their DETS files. `mix undercity.reset` wipes both data directories.
