defmodule UndercityServer.Actions.Eat do
  @moduledoc """
  Handles eating an item from the player's inventory, applying the food effect.

  - Delegates entirely to `Player.eat_item/2` which runs atomically inside the Player GenServer
  - Validates the item exists, is edible, and that the player can spend AP
  - Mutates inventory and health; persists the result before replying
  """

  alias UndercityServer.Player

  @doc """
  Eats the item at `index` in the player's inventory.

  - Returns `{:ok, item, effect, ap, hp}` on success, where `effect` is `{:heal, n}` or `{:damage, n}`.
  - Returns `{:error, :invalid_index}` if no item exists at that position.
  - Returns `{:error, :not_edible, item_name}` if the item cannot be eaten.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  def eat(player_id, index) do
    Player.eat_item(player_id, index)
  end
end
