defmodule UndercityCli.Commands.Search do
  @moduledoc """
  Handles the `search` command, looking for hidden items in the current block.

  - Calls the Gateway `:search` action, costing AP
  - Updates `state.ap` on success; outcome messages are delivered via the server inbox
  """

  alias UndercityCli.Commands

  @doc "Returns the usage hint string for the search command."
  def usage, do: "search"

  @doc """
  Dispatches the search command, calling the Gateway `:search` action.

  - Updates `state.ap` on any outcome.
  """
  def dispatch(_verb, state) do
    state.player_id
    |> state.gateway.perform(state.vicinity.id, :search, nil)
    |> Commands.handle_action(state, fn
      {:ok, new_ap}, state -> %{state | ap: new_ap}
    end)
  end
end
