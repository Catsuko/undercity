# Testing

Each app has its own `test/` directory and runs independently. Use `mix.bat test` on Windows/MSYS2.

## Three Layers

**`undercity_core`** — pure unit tests, no processes. Call module functions directly with plain structs. Always `async: true`.

**`undercity_server`** — tests for GenServers and actions. Use `Test.Helpers` to spin up isolated block and player processes. Tests that go through `Gateway` against the live application are integration tests and must be `async: false`.

**`undercity_cli`** — command dispatch and view tests. No real server processes — inject fake gateway and message buffer modules. Always `async: true` except `MessageBufferTest` (globally named process).

## Test.Helpers (server tests)

`UndercityServer.Test.Helpers` provides two helpers that start supervised processes with isolated DETS state and register automatic cleanup:

- **`start_block!(opts)`** — starts a `Block.Supervisor` (Store + Block). Key options: `:type` (block type atom), `:random` (zero-arity fn returning a float, for controlling loot rolls deterministically).
- **`start_player!(opts)`** — starts a `Player` GenServer. Key option: `:name`. New players start at 50 AP / 50 HP.

Tests using these helpers are safe to run `async: true`. Tests using the live app (Gateway, world map) must be `async: false`.

## CLI Mocking

CLI tests use [Mimic](https://hex.pm/packages/mimic) to mock `UndercityServer.Gateway`, `UndercityCli.MessageBuffer`, and `UndercityCli.View.InventorySelector` per-process. Modules are registered in `test_helper.exs` with `Mimic.copy/1`. Tests use `expect/3` to set up per-call overrides and verify they were invoked, or `stub/3` for unverified overrides (e.g. loops with variable call counts). Mocks are process-scoped so `async: true` is safe.

## Common Patterns

**Deterministic loot rolls** — pass a fixed-return lambda to `start_block!(:random)` to force a hit or miss:
```elixir
start_block!(type: :graveyard, random: fn -> 0.05 end)  # always finds
start_block!(type: :graveyard, random: fn -> 0.99 end)  # always misses
```

**AP exhaustion** — drain AP with `Player.perform` in a comprehension, then assert `:exhausted`.

**Collapsed player** — zero out HP directly with `:sys.replace_state/2`.
