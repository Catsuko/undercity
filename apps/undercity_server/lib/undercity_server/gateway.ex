defmodule UndercityServer.Gateway do
  @moduledoc """
  Client SDK for the undercity game server.

  Gateway is the public API for interacting with the game world. It acts as
  a thin facade, delegating to Session for player lifecycle and to Action
  modules for gameplay operations.
  """

  defdelegate connect(player_name), to: UndercityServer.Session
  defdelegate enter(name), to: UndercityServer.Session
  defdelegate move(player_id, direction, from_block_id), to: UndercityServer.Actions.Movement
  defdelegate search(player_id, block_id), to: UndercityServer.Actions.Search
  defdelegate scribble(player_id, block_id, text), to: UndercityServer.Actions.Scribble
  defdelegate get_inventory(player_id), to: UndercityServer.Actions.Inventory
end
