defmodule UndercityServer.Actions.Inventory do
  @moduledoc """
  Handles player inventory actions.
  """

  alias UndercityServer.Player

  @doc """
  Returns the player's current inventory items.
  """
  def get_inventory(player_id) do
    Player.get_inventory(player_id)
  end
end
