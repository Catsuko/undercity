defmodule UndercityCli.Commands.Drop do
  @moduledoc """
  Handles drop commands (bare and indexed).
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.View.InventorySelector

  def dispatch(command, state, gateway, message_buffer, selector \\ InventorySelector)

  def dispatch("drop", state, gateway, message_buffer, selector) do
    case select_from_inventory(state, gateway, selector, "Drop which item?") do
      :cancel -> GameState.continue(state)
      {:ok, index} -> drop(index, state, gateway, message_buffer)
    end
  end

  def dispatch({"drop", index_str}, state, gateway, message_buffer, _selector) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        drop(n - 1, state, gateway, message_buffer)

      _ ->
        message_buffer.warn("Invalid item selection.")
        GameState.continue(state)
    end
  end

  defp drop(index, state, gateway, message_buffer) do
    state.player_id
    |> gateway.drop_item(index)
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, item_name, new_ap} ->
        message_buffer.info("You dropped #{item_name}.")
        GameState.continue(state, new_ap, state.hp)

      {:error, :invalid_index} ->
        message_buffer.warn("Invalid item selection.")
        GameState.continue(state)
    end)
  end

  defp select_from_inventory(state, gateway, selector, label) do
    state.player_id
    |> gateway.check_inventory()
    |> selector.select(label)
  end
end
