defmodule UndercityCli do
  @moduledoc """
  Terminal client for Undercity that connects to a running server node via distributed Erlang.

  - Starts via `mix undercity.join --player <name>` and runs a Ratatouille TEA game loop
  - Routes player input through `Commands`, which dispatches to per-verb command modules
  - Communicates with the server exclusively through `UndercityServer.Gateway` — no direct `UndercityCore` type references
  - Accumulates feedback messages in `MessageBuffer` and flushes them to the log panel after each command
  - Supports interactive selection overlays (`View.Selection`) for multi-stage commands
  """
end
