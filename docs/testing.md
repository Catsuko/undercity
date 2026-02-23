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

## CLI Fakes

CLI tests inject fake modules in place of the gateway and message buffer. `FakeMessageBuffer` sends `{:warn | :info | :success, msg}` tuples to `self()` — assert with `assert_received`. Common fake gateways (`ExhaustedGateway`, `CollapsedGateway`, etc.) live in `test/support/fakes.ex`; action-specific fakes are defined at the top of the relevant test file.

## Common Patterns

**Deterministic loot rolls** — pass a fixed-return lambda to `start_block!(:random)` to force a hit or miss:
```elixir
start_block!(type: :graveyard, random: fn -> 0.05 end)  # always finds
start_block!(type: :graveyard, random: fn -> 0.99 end)  # always misses
```

**AP exhaustion** — drain AP with `Player.perform` in a comprehension, then assert `:exhausted`.

**Collapsed player** — zero out HP directly with `:sys.replace_state/2`.
