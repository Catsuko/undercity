defmodule UndercityServer.Actions.Inventory do
  @moduledoc """
  Handles player inventory actions.

  Currently provides read access to inventory. Future operations like
  drop, equip, and trade belong here.
  """

  alias UndercityServer.Player

  @doc """
  Returns the player's current inventory items.
  """
  def get_inventory(player_id) do
    Player.get_inventory(player_id)
  end
end
