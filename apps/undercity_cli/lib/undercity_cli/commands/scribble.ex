defmodule UndercityCli.Commands.Scribble do
  @moduledoc """
  Handles the `scribble` command, writing a message to the current block's surface.

  - `scribble <text>` — performs the scribble action via Gateway, costing AP
  - Emits a warning if chalk is missing or no text is provided
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.BlockDescription

  @doc "Returns the usage hint string for the scribble command."
  def usage, do: "scribble <text>"

  @doc """
  Dispatches the scribble command.

  - Emits a usage warning and returns state unchanged when called without text.
  - Calls the Gateway `:scribble` action and updates `state.ap` on success.
  """
  def dispatch("scribble", state) do
    MessageBuffer.warn("Usage: scribble <text>")
    state
  end

  def dispatch({"scribble", text}, state) do
    state.player_id
    |> state.gateway.perform(state.vicinity.id, :scribble, text)
    |> Commands.handle_action(state, fn
      {:ok, new_ap}, state ->
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
