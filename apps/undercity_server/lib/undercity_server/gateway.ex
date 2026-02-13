defmodule UndercityServer.Gateway do
  @moduledoc """
  Public API for interacting with the game server.

  Gateway is a thin facade that delegates to domain modules. It serves as a
  table of contents for what clients can do — each function is a one-line
  delegation to a Session or Actions module.

  To add a new client operation: implement it in the appropriate Actions
  module (or create a new one under Actions), then add a `defdelegate` here.
  """

  defdelegate connect(player_name), to: UndercityServer.Session
  defdelegate enter(name), to: UndercityServer.Session
  defdelegate move(player_id, direction, from_block_id), to: UndercityServer.Actions.Movement
  defdelegate search(player_id, block_id), to: UndercityServer.Actions.Search
  defdelegate scribble(player_id, block_id, text), to: UndercityServer.Actions.Scribble
  defdelegate get_inventory(player_id), to: UndercityServer.Actions.Inventory
  defdelegate get_ap(player_id), to: UndercityServer.Player
end
