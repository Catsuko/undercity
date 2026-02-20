defmodule UndercityCli.Commands.Scribble do
  @moduledoc """
  Handles the scribble command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.BlockDescription
  alias UndercityServer.Gateway

  def dispatch("scribble", _player_id, _vicinity, ap, hp) do
    MessageBuffer.warn("Usage: scribble <text>")
    {:acted, ap, hp}
  end

  def dispatch({"scribble", text}, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :scribble, text)
    |> Commands.handle_action(ap, hp, fn
      {:ok, new_ap} ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(vicinity)}.")
        {:acted, new_ap, hp}

      {:error, :empty_message} ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(vicinity)}.")
        {:acted, ap, hp}

      {:error, :item_missing} ->
        MessageBuffer.warn("You have no chalk.")
        {:acted, ap, hp}
    end)
  end
end
