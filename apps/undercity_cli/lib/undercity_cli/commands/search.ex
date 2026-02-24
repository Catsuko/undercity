defmodule UndercityCli.Commands.Search do
  @moduledoc """
  Handles the search command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState

  def usage, do: "search"

  def dispatch(_verb, state, gateway, message_buffer) do
    state.player_id
    |> gateway.perform(state.vicinity.id, :search, nil)
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, {:found, item}, new_ap} ->
        message_buffer.success("You found #{item.name}!")
        GameState.continue(state, new_ap, state.hp)

      {:ok, {:found_but_full, item}, new_ap} ->
        message_buffer.warn("You found #{item.name}, but your inventory is full.")
        GameState.continue(state, new_ap, state.hp)

      {:ok, :nothing, new_ap} ->
        message_buffer.warn("You find nothing.")
        GameState.continue(state, new_ap, state.hp)
    end)
  end
end
