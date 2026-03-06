defmodule UndercityCli.Commands.Move do
  @moduledoc "Handles movement commands."

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Vicinity

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

  def usage, do: "north, south, east, west (or n, s, e, w), enter, exit"

  def dispatch(verb, state) do
    direction = Map.fetch!(@directions, verb)

    state.player_id
    |> state.gateway.perform(state.vicinity.id, :move, direction)
    |> Commands.handle_action(state, fn
      {:ok, {:ok, new_vicinity}, new_ap}, state ->
        MessageBuffer.info("You move to #{Vicinity.name(new_vicinity)}.")
        %{state | vicinity: new_vicinity, ap: new_ap}

      {:ok, {:error, :no_exit}, new_ap}, state ->
        MessageBuffer.warn("You can't go that way.")
        %{state | ap: new_ap}
    end)
  end
end
