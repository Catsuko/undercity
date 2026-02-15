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
      block_id |> Block.search() |> pick_up(player_id)
    end)
  end

  defp pick_up({:found, item}, player_id) do
    case Player.add_item(player_id, item) do
      :ok -> {:found, item}
      {:error, :full} -> {:found_but_full, item}
    end
  end

  defp pick_up(:nothing, _player_id), do: :nothing
end
