defmodule UndercityServer.Actions.Search do
  @moduledoc """
  Handles searching blocks for items.

  Delegates the loot roll to the Block process, then adds any found item
  to the player's inventory.
  """

  alias UndercityServer.Block
  alias UndercityServer.Player

  @doc """
  Performs a search action for the given player in the given block.
  Returns `{:ok, result, ap}` or `{:error, :exhausted}`.
  """
  def search(player_id, block_id) do
    Player.perform(player_id, fn ->
      case Block.search(block_id) do
        {:found, item} ->
          Player.add_item(player_id, item)
          {:found, item}

        :nothing ->
          :nothing
      end
    end)
  end
end
