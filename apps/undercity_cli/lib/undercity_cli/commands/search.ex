defmodule UndercityCli.Commands.Search do
  @moduledoc """
  Handles the search command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  def dispatch(_verb, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :search, nil)
    |> Commands.handle_action(ap, hp, fn
      {:ok, {:found, item}, new_ap} ->
        MessageBuffer.success("You found #{item.name}!")
        {:acted, new_ap, hp}

      {:ok, {:found_but_full, item}, new_ap} ->
        MessageBuffer.warn("You found #{item.name}, but your inventory is full.")
        {:acted, new_ap, hp}

      {:ok, :nothing, new_ap} ->
        MessageBuffer.warn("You find nothing.")
        {:acted, new_ap, hp}
    end)
  end
end
