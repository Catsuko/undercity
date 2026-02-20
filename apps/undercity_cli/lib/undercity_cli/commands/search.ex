defmodule UndercityCli.Commands.Search do
  @moduledoc """
  Handles the search command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  def dispatch(_verb, state) do
    state.player_id
    |> Gateway.perform(state.vicinity.id, :search, nil)
    |> Commands.handle_action(state, fn
      {:ok, {:found, item}, new_ap} ->
        MessageBuffer.success("You found #{item.name}!")
        GameState.continue(state, new_ap, state.hp)

      {:ok, {:found_but_full, item}, new_ap} ->
        MessageBuffer.warn("You found #{item.name}, but your inventory is full.")
        GameState.continue(state, new_ap, state.hp)

      {:ok, :nothing, new_ap} ->
        MessageBuffer.warn("You find nothing.")
        GameState.continue(state, new_ap, state.hp)
    end)
  end
end
