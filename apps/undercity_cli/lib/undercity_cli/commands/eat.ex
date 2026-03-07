defmodule UndercityCli.Commands.Eat do
  @moduledoc "Handles eat commands (bare and indexed)."

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Selection
  alias UndercityCli.MessageBuffer

  def usage, do: "eat [n]"

  def dispatch(verb, state) when is_binary(verb) do
    Selection.from_inventory(state, verb, "Your inventory is empty.", "Eat which item?")
  end

  # Typed "eat 1" — parse index and delegate to canonical form
  def dispatch({verb, index}, state) when is_binary(index) do
    case Integer.parse(index) do
      {n, ""} when n >= 1 -> dispatch({verb, n - 1}, state)
      _ -> handle_outcome({:error, :invalid_index}, state)
    end
  end

  # Canonical form — execute
  def dispatch({_verb, index}, state) when is_integer(index) do
    state.player_id
    |> state.gateway.perform(state.vicinity.id, :eat, index)
    |> Commands.handle_action(state, &handle_outcome/2)
  end

  defp handle_outcome({:ok, item, _effect, new_ap, new_hp}, state) do
    MessageBuffer.success("Ate a #{item.name}.")
    %{state | ap: new_ap, hp: new_hp}
  end

  defp handle_outcome({:error, :not_edible, item_name}, state) do
    MessageBuffer.warn("You can't eat #{item_name}.")
    state
  end

  defp handle_outcome({:error, :invalid_index}, state) do
    MessageBuffer.warn("Invalid item selection.")
    state
  end
end
