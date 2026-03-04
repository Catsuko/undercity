defmodule UndercityCli do
  @moduledoc """
  The Undercity command-line client.

  Connects to a running `UndercityServer` node via distributed Erlang and provides
  the interactive terminal interface. Started with `mix undercity.join --player <name>`.

  ## Architecture

  The client is a Ratatouille TEA application (`UndercityCli.App`). All state lives
  in the model; keypresses accumulate in `model.input` and are dispatched on Enter.
  A subscription polls for server messages every 500 ms. Press `q` to quit.

  ## Commands

  `UndercityCli.Commands` routes input strings to command modules via a compile-time
  verb-to-module map. Each command module calls `Gateway` on the server and returns
  an updated `GameState`. Exhaustion and collapse errors are normalised in one place
  by `Commands.handle_action/4` so individual commands don't handle them.

  ## Talking to the server

  All server interaction goes through `UndercityServer.Gateway`. Because the CLI
  connects as a distributed Erlang node, these are regular function calls — the node
  boundary is transparent. The CLI intentionally does not reference `UndercityCore`
  types directly; it only works with what `Gateway` returns (e.g. `Vicinity`).

  ## Rendering

  `UndercityCli.App.render/1` builds a Ratatouille view tree from the current model.
  Messages are accumulated in `MessageBuffer` during command dispatch and flushed
  after each command.

  ## Testing

  Command modules accept the gateway and message buffer as injected arguments, so
  tests mock them with Mimic per-process — no real server process is needed to test CLI logic.
  """
end
