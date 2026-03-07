defmodule UndercityCli.Commands.Eat do
  @moduledoc "Handles eat commands (bare and indexed)."

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.State

  def usage, do: "eat [n]"

  def dispatch("eat", state) do
    case state.gateway.check_inventory(state.player_id) do
      [] ->
        MessageBuffer.warn("Your inventory is empty.")
        state

      items ->
        state
        |> State.pending("eat", [])
        |> State.select("Eat which item?", items)
    end
  end

  # Typed "eat 1" — parse index and delegate to canonical form
  def dispatch({"eat", index_str}, state) when is_binary(index_str) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        dispatch({"eat", n - 1}, state)

      _ ->
        MessageBuffer.warn("Invalid item selection.")
        state
    end
  end

  # Canonical form — execute
  def dispatch({"eat", index}, state) when is_integer(index) do
    state.player_id
    |> state.gateway.perform(state.vicinity.id, :eat, index)
    |> Commands.handle_action(state, fn
      {:ok, item, _effect, new_ap, new_hp}, state ->
        MessageBuffer.success("Ate a #{item.name}.")
        %{state | ap: new_ap, hp: new_hp}

      {:error, :not_edible, item_name}, state ->
        MessageBuffer.warn("You can't eat #{item_name}.")
        state

      {:error, :invalid_index}, state ->
        MessageBuffer.warn("Invalid item selection.")
        state
    end)
  end
end
