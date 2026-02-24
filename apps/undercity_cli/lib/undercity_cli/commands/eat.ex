defmodule UndercityCli.Commands.Eat do
  @moduledoc """
  Handles eat commands (bare and indexed).
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.View.InventorySelector

  def usage, do: "eat [n]"

  def dispatch(command, state, gateway, message_buffer, selector \\ InventorySelector)

  def dispatch("eat", state, gateway, message_buffer, selector) do
    case select_from_inventory(state, gateway, selector, "Eat which item?") do
      :cancel -> GameState.continue(state)
      {:ok, index} -> eat(index, state, gateway, message_buffer)
    end
  end

  def dispatch({"eat", index_str}, state, gateway, message_buffer, _selector) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        eat(n - 1, state, gateway, message_buffer)

      _ ->
        message_buffer.warn("Invalid item selection.")
        GameState.continue(state)
    end
  end

  defp eat(index, state, gateway, message_buffer) do
    state.player_id
    |> gateway.perform(state.vicinity.id, :eat, index)
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, item, _effect, new_ap, new_hp} ->
        message_buffer.success("Ate a #{item.name}.")
        GameState.continue(state, new_ap, new_hp)

      {:error, :not_edible, item_name} ->
        message_buffer.warn("You can't eat #{item_name}.")
        GameState.continue(state)

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
