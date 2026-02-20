defmodule UndercityCli.Commands.Move do
  @moduledoc """
  Handles movement commands (north, south, east, west, enter, exit).
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState

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

  def dispatch(verb, state, gateway, message_buffer) do
    direction = Map.fetch!(@directions, verb)

    state.player_id
    |> gateway.perform(state.vicinity.id, :move, direction)
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, {:ok, new_vicinity}, new_ap} ->
        GameState.moved(state, new_vicinity, new_ap, state.hp)

      {:ok, {:error, :no_exit}, new_ap} ->
        message_buffer.warn("You can't go that way.")
        GameState.continue(state, new_ap, state.hp)
    end)
  end
end
