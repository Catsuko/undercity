defmodule UndercityCli.Commands.Eat do
  @moduledoc """
  Handles eat commands (bare and indexed).
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.InventorySelector
  alias UndercityServer.Gateway

  def dispatch("eat", state) do
    case select_from_inventory(state, "Eat which item?") do
      :cancel -> GameState.continue(state)
      {:ok, index} -> eat(index, state)
    end
  end

  def dispatch({"eat", index_str}, state) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        eat(n - 1, state)

      _ ->
        MessageBuffer.warn("Invalid item selection.")
        GameState.continue(state)
    end
  end

  defp eat(index, state) do
    state.player_id
    |> Gateway.perform(state.vicinity.id, :eat, index)
    |> Commands.handle_action(state, fn
      {:ok, item, _effect, new_ap, new_hp} ->
        MessageBuffer.success("Ate a #{item.name}.")
        GameState.continue(state, new_ap, new_hp)

      {:error, :not_edible, item_name} ->
        MessageBuffer.warn("You can't eat #{item_name}.")
        GameState.continue(state)

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
