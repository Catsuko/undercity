defmodule UndercityCli.Commands.Drop do
  @moduledoc "Handles drop commands (bare and indexed)."

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Selection
  alias UndercityCli.MessageBuffer

  def usage, do: "drop [n]"

  # Bare "drop" — fetch inventory and set up selection overlay
  def dispatch(verb, state) when is_binary(verb) do
    Selection.from_inventory(state, verb, "Your inventory is empty.", "Drop which item?")
  end

  # Typed "drop 1" — parse index and delegate to canonical form
  def dispatch({verb, index}, state) when is_binary(index) do
    case Integer.parse(index) do
      {n, ""} when n >= 1 -> dispatch({verb, n - 1}, state)
      _ -> handle_outcome({:error, :invalid_index}, state)
    end
  end

  # Canonical form — execute
  def dispatch({_verb, index}, state) when is_integer(index) do
    state.player_id
    |> state.gateway.drop_item(index)
    |> Commands.handle_action(state, &handle_outcome/2)
  end

  defp handle_outcome({:ok, item_name, new_ap}, state) do
    MessageBuffer.info("You dropped #{item_name}.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:error, :invalid_index}, state) do
    MessageBuffer.warn("Invalid item selection.")
    state
  end
end
