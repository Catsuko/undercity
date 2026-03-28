defmodule UndercityCli.Commands.Move do
  @moduledoc """
  Handles movement commands, updating the player's vicinity after a successful move.

  - Accepts directional verbs: `north`, `south`, `east`, `west` (and aliases `n`, `s`, `e`, `w`), `enter`, `exit`
  - Calls the Gateway `:move` action and updates `state.vicinity` and `state.ap` on success
  - Emits a warning if the chosen direction has no exit
  """

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

  @doc "Returns the usage hint string for movement commands."
  def usage, do: "north, south, east, west (or n, s, e, w), enter, exit"

  @doc """
  Dispatches a movement command for the given directional verb.

  - Updates `state.vicinity` and `state.ap` on a successful move.
  - Emits a warning and updates only `state.ap` when there is no exit in that direction.
  """
  def dispatch(verb, state) do
    direction = Map.fetch!(@directions, verb)

    state.player_id
    |> state.gateway.perform(state.vicinity.id, :move, direction)
    |> Commands.handle_action(state, fn
      {:ok, {:ok, new_vicinity}, new_ap}, state ->
        MessageBuffer.info(move_message(direction, new_vicinity))
        %{state | vicinity: new_vicinity, ap: new_ap}

      {:ok, {:error, :no_exit}, new_ap}, state ->
        MessageBuffer.warn("You can't go that way.")
        %{state | ap: new_ap}
    end)
  end

  defp move_message(:enter, vicinity), do: "You enter #{Vicinity.name(vicinity)}."
  defp move_message(:exit, vicinity), do: "You exit #{Vicinity.name(vicinity)}."
  defp move_message(_direction, vicinity), do: "You move to #{Vicinity.name(vicinity)}."
end
