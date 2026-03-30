defmodule UndercityServer.Actions.Search do
  @moduledoc """
  Handles searching blocks for items.

  Delegates the loot roll to the Block process, then adds any found item
  to the player's inventory. Writes a typed inbox message to the player
  describing the outcome.
  """

  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Inbox, as: PlayerInbox

  @doc """
  Executes a search action for `player_id` in `block_id`, spending 1 AP.

  - Returns `{:ok, ap}` on any outcome (found, found but full, or nothing).
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  def search(player_id, block_id) do
    case Player.perform(player_id, fn ->
           block_id |> Block.search() |> pick_up(player_id)
         end) do
      {:ok, result, ap} ->
        write_message(player_id, result)
        {:ok, ap}

      {:error, _} = error ->
        error
    end
  end

  defp pick_up({:found, item}, player_id) do
    case Player.add_item(player_id, item) do
      :ok -> {:found, item}
      {:error, :full} -> {:found_but_full, item}
    end
  end

  defp pick_up(:nothing, _player_id), do: :nothing

  defp write_message(player_id, {:found, item}), do: PlayerInbox.success(player_id, "You found #{item.name}!")

  defp write_message(player_id, {:found_but_full, item}),
    do: PlayerInbox.warning(player_id, "You found #{item.name}, but your inventory is full.")

  defp write_message(player_id, :nothing), do: PlayerInbox.warning(player_id, "You find nothing.")
end
