defmodule UndercityServer.Gateway do
  @moduledoc """
  Public API for interacting with the game server.

  Gateway is a thin facade that delegates to domain modules. Player actions
  route through `perform/4`, which dispatches to the appropriate Actions
  module. To add a new action: implement it in an Actions module, then add
  a `perform` clause here.
  """

  alias UndercityServer.Actions

  defdelegate connect(player_name), to: UndercityServer.Session
  defdelegate enter(name), to: UndercityServer.Session
  defdelegate get_inventory(player_id), to: Actions.Inventory
  defdelegate get_ap(player_id), to: UndercityServer.Player

  def perform(player_id, block_id, :move, direction), do: Actions.Movement.move(player_id, block_id, direction)
  def perform(player_id, block_id, :search, _args), do: Actions.Search.search(player_id, block_id)
  def perform(player_id, block_id, :scribble, text), do: Actions.Scribble.scribble(player_id, block_id, text)
end
