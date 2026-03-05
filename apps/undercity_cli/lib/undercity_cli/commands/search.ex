defmodule UndercityCli.Commands.Search do
  @moduledoc "Handles the search command."

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer

  def usage, do: "search"

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
