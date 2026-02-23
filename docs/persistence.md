# Persistence

Undercity uses DETS (Disk-based Erlang Term Storage) for all persistence — no external database. DETS stores Erlang terms on disk as key/value pairs. Each table is a single file, owned by a GenServer that serialises concurrent access.

## Two Stores

**Player store** — a single shared DETS table (`data/players/players.dets`) holding all player records, keyed by player ID. Managed by `Player.Store`.

**Block store** — one DETS file per world block (`data/blocks/<block_id>.dets`), holding that block's current state (present players, scribble, etc.). Managed by `Block.Store`. One `Block.Store` process per block, started at boot.

## Key Properties

- **Synchronous writes** — all writes happen inside `handle_call` callbacks, so every mutating operation completes before returning to the caller. No write-behind or batching.
- **On-restart recovery** — block and player processes load from their DETS files in `init/1`. If no file exists, they start with fresh state.
- **Test isolation** — `config/test.exs` redirects the data directory to `test/data/` so tests never touch production data. Test helpers clean up DETS files automatically.

## Resetting

`mix undercity.reset` deletes `data/blocks/` and `data/players/`. Run it with the server stopped. The next server start recreates fresh state.
