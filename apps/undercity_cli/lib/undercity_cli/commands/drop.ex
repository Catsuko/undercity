defmodule UndercityCli.Commands.Drop do
  @moduledoc """
  Handles drop commands (bare and indexed).
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.InventorySelector
  alias UndercityServer.Gateway

  def dispatch("drop", state) do
    case select_from_inventory(state, "Drop which item?") do
      :cancel -> GameState.continue(state)
      {:ok, index} -> drop(index, state)
    end
  end

  def dispatch({"drop", index_str}, state) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        drop(n - 1, state)

      _ ->
        MessageBuffer.warn("Invalid item selection.")
        GameState.continue(state)
    end
  end

  defp drop(index, state) do
    state.player_id
    |> Gateway.drop_item(index)
    |> Commands.handle_action(state, fn
      {:ok, item_name, new_ap} ->
        MessageBuffer.info("You dropped #{item_name}.")
        GameState.continue(state, new_ap, state.hp)

      {:error, :invalid_index} ->
        MessageBuffer.warn("Invalid item selection.")
        GameState.continue(state)
    end)
  end

  defp select_from_inventory(state, label) do
    state.player_id
    |> Gateway.check_inventory()
    |> InventorySelector.select(label)
  end
end
