defmodule UndercityServer do
  @moduledoc """
  The Undercity game server.

  Runs as a named Erlang node (`undercity_server@127.0.0.1`). Manages all runtime
  state via OTP processes and persists it to DETS files. Started with
  `mix undercity.server`.

  ## Process model

  - One `Block` GenServer per world block, started statically at boot alongside its
    `Block.Store` (DETS-backed) under a `:rest_for_one` supervisor.
  - One `Player` GenServer per connected player, started dynamically by
    `Player.Supervisor` when a player connects.
  - One shared `Player.Store` GenServer for the player DETS table.

  GenServers that need to be called from the CLI node are registered under names that
  include the node target. `UndercityServer.server_node/0` returns the correct node
  atom (or `node()` when running without distribution, e.g. in tests).

  ## Public API

  `UndercityServer.Gateway` is the single entry point for all client interactions —
  the CLI calls nothing in this app directly except `Gateway`. It routes actions to
  `Actions.*` modules and delegates inventory/session calls to `Player` and `Session`.

  ## Key modules

  - `Gateway` — public API surface for the CLI.
  - `Session` — player connect/reconnect lifecycle.
  - `Player` — per-player GenServer; owns inventory, AP, and HP; gates actions via AP.
  - `Block` — per-block GenServer; tracks present players and scribble.
  - `Vicinity` — snapshot of a player's surroundings, built from live server state
    and returned to the CLI after movement or on connect.
  - `Actions.*` — one module per player action (movement, search, scribble, eat).
  """

  def server_node do
    if Node.alive?(), do: :"undercity_server@127.0.0.1", else: node()
  end

  def data_dir do
    Application.get_env(:undercity_server, :data_dir, "data")
  end
end
