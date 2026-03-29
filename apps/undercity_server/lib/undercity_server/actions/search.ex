defmodule UndercityServer.Actions.Search do
  @moduledoc """
  Handles searching blocks for items.

  Delegates the loot roll to the Block process, then adds any found item
  to the player's inventory.
  """

  alias UndercityServer.Block
  alias UndercityServer.Player

  @doc """
  Executes a search action for `player_id` in `block_id`, spending 1 AP.

  - Returns `{:ok, {:found, item}, ap}` when an item is found and added to inventory.
  - Returns `{:ok, {:found_but_full, item}, ap}` when an item is found but inventory is full.
  - Returns `{:ok, :nothing, ap}` when the search yields nothing.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
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
