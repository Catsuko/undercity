defmodule UndercityCli.Commands.Drop do
  @moduledoc """
  Handles the `drop` command, removing an item from the player's inventory.

  - `drop` — opens an inventory selector overlay
  - `drop <n>` — drops the 1-based item at index `n` directly via Gateway
  - Re-dispatch stage `{"drop", item_idx}` (integer) — executes the drop
  """

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Selection
  alias UndercityCli.MessageBuffer

  @doc "Returns the usage hint string for the drop command."
  def usage, do: "drop [n]"

  @doc """
  Dispatches a drop command, routing through the selection pipeline as needed.

  - Opens an inventory overlay when called with a bare verb string.
  - Parses and delegates to the canonical integer-index form when called with a string index.
  - Executes via Gateway when called with an integer index.
  """
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
