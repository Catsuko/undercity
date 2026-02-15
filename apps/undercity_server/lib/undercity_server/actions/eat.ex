defmodule UndercityServer.Actions.Eat do
  @moduledoc """
  Handles eating items from inventory.

  Looks up the item by index, checks if it's edible, consumes it,
  and applies the food effect to the player's health.
  """

  alias UndercityServer.Player

  def eat(player_id, index) do
    Player.eat_item(player_id, index)
  end
end
