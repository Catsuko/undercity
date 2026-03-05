defmodule UndercityCli.Commands.Scribble do
  @moduledoc "Handles the scribble command."

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.BlockDescription

  def usage, do: "scribble <text>"

  def dispatch("scribble", state) do
    MessageBuffer.warn("Usage: scribble <text>")
    state
  end

  def dispatch({"scribble", text}, state) do
    state.player_id
    |> state.gateway.perform(state.vicinity.id, :scribble, text)
    |> Commands.handle_action(state, fn
      {:ok, new_ap}, state ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(state.vicinity)}.")
        %{state | ap: new_ap}

      {:error, :empty_message}, state ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(state.vicinity)}.")
        state

      {:error, :item_missing}, state ->
        MessageBuffer.warn("You have no chalk.")
        state
    end)
  end
end
