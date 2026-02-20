defmodule UndercityCli.Commands.Scribble do
  @moduledoc """
  Handles the scribble command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.View.BlockDescription

  def dispatch("scribble", state, _gateway, message_buffer) do
    message_buffer.warn("Usage: scribble <text>")
    GameState.continue(state)
  end

  def dispatch({"scribble", text}, state, gateway, message_buffer) do
    state.player_id
    |> gateway.perform(state.vicinity.id, :scribble, text)
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, new_ap} ->
        message_buffer.success("You scribble #{BlockDescription.scribble_surface(state.vicinity)}.")
        GameState.continue(state, new_ap, state.hp)

      {:error, :empty_message} ->
        message_buffer.success("You scribble #{BlockDescription.scribble_surface(state.vicinity)}.")
        GameState.continue(state)

      {:error, :item_missing} ->
        message_buffer.warn("You have no chalk.")
        GameState.continue(state)
    end)
  end
end
