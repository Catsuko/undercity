defmodule UndercityCli.Commands.Eat do
  @moduledoc """
  Handles the `eat` command, consuming a food item from the player's inventory.

  - `eat` — opens an inventory selector overlay
  - `eat <n>` — eats the 1-based item at index `n` directly via Gateway
  - Re-dispatch stage `{"eat", item_idx}` (integer) — executes the eat action
  """

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Selection
  alias UndercityCli.MessageBuffer

  @doc "Returns the usage hint string for the eat command."
  def usage, do: "eat [n]"

  @doc """
  Dispatches an eat command, routing through the selection pipeline as needed.

  - Opens an inventory overlay when called with a bare verb string.
  - Parses and delegates to the canonical integer-index form when called with a string index.
  - Executes via Gateway when called with an integer index.
  """
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

  defp handle_outcome({:ok, new_ap, new_hp}, state) do
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
