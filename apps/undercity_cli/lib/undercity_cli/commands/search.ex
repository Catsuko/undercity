defmodule UndercityCli.Commands.Search do
  @moduledoc """
  Handles the `search` command, looking for hidden items in the current block.

  - Calls the Gateway `:search` action, costing AP
  - Reports what was found (item name), whether the inventory was full, or that nothing was found
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer

  @doc "Returns the usage hint string for the search command."
  def usage, do: "search"

  @doc """
  Dispatches the search command, calling the Gateway `:search` action.

  - Updates `state.ap` on any outcome.
  - Emits a success message with the item name on `:found`.
  - Emits a warning if the inventory was full or nothing was found.
  """
  def dispatch(_verb, state) do
    state.player_id
    |> state.gateway.perform(state.vicinity.id, :search, nil)
    |> Commands.handle_action(state, fn
      {:ok, {:found, item}, new_ap}, state ->
        MessageBuffer.success("You found #{item.name}!")
        %{state | ap: new_ap}

      {:ok, {:found_but_full, item}, new_ap}, state ->
        MessageBuffer.warn("You found #{item.name}, but your inventory is full.")
        %{state | ap: new_ap}

      {:ok, :nothing, new_ap}, state ->
        MessageBuffer.warn("You find nothing.")
        %{state | ap: new_ap}
    end)
  end
end
