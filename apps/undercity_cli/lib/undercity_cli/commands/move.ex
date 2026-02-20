defmodule UndercityCli.Commands.Move do
  @moduledoc """
  Handles movement commands (north, south, east, west, enter, exit).
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
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

  def dispatch(verb, state) do
    direction = Map.fetch!(@directions, verb)

    state.player_id
    |> Gateway.perform(state.vicinity.id, :move, direction)
    |> Commands.handle_action(state, fn
      {:ok, {:ok, new_vicinity}, new_ap} ->
        GameState.moved(state, new_vicinity, new_ap, state.hp)

      {:ok, {:error, :no_exit}, new_ap} ->
        MessageBuffer.warn("You can't go that way.")
        GameState.continue(state, new_ap, state.hp)
    end)
  end
end
