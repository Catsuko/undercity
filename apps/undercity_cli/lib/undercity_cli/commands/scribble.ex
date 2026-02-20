defmodule UndercityCli.Commands.Scribble do
  @moduledoc """
  Handles the scribble command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.BlockDescription
  alias UndercityServer.Gateway

  def dispatch("scribble", state) do
    MessageBuffer.warn("Usage: scribble <text>")
    GameState.continue(state)
  end

  def dispatch({"scribble", text}, state) do
    state.player_id
    |> Gateway.perform(state.vicinity.id, :scribble, text)
    |> Commands.handle_action(state, fn
      {:ok, new_ap} ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(state.vicinity)}.")
        GameState.continue(state, new_ap, state.hp)

      {:error, :empty_message} ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(state.vicinity)}.")
        GameState.continue(state)

      {:error, :item_missing} ->
        MessageBuffer.warn("You have no chalk.")
        GameState.continue(state)
    end)
  end
end
