defmodule UndercityCli.Commands.Move do
  @moduledoc """
  Handles movement commands (north, south, east, west, enter, exit).
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  @directions %{
    "north" => :north,
    "south" => :south,
    "east" => :east,
    "west" => :west,
    "n" => :north,
    "s" => :south,
    "e" => :east,
    "w" => :west,
    "enter" => :enter,
    "exit" => :exit
  }

  def dispatch(verb, player_id, vicinity, ap, hp) do
    direction = Map.fetch!(@directions, verb)

    player_id
    |> Gateway.perform(vicinity.id, :move, direction)
    |> Commands.handle_action(ap, hp, fn
      {:ok, {:ok, new_vicinity}, new_ap} ->
        {:moved, new_vicinity, new_ap, hp}

      {:ok, {:error, :no_exit}, new_ap} ->
        MessageBuffer.warn("You can't go that way.")
        {:acted, new_ap, hp}
    end)
  end
end
