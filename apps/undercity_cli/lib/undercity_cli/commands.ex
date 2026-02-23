defmodule UndercityCli.Commands do
  @moduledoc """
  Routes parsed input to the appropriate command module.

  Splits raw input into a verb (and optional rest), looks up the verb in the
  routing table, and delegates to the matching command module. Each command
  module implements `dispatch/4` and returns `{:moved, state}` or
  `{:continue, state}`. The game loop uses the tag to decide what to re-render.

  `gateway` and `message_buffer` are passed explicitly so command modules can
  be tested in isolation without live server processes or terminal I/O.

  Also exposes `handle_action/4`, a shared helper used by command modules to
  normalise Gateway results — catching exhaustion/collapse before delegating
  to the command-specific callback.
  """

  alias UndercityCli.GameState

  @command_routes [
    {UndercityCli.Commands.Move, ["north", "south", "east", "west", "n", "s", "e", "w", "enter", "exit"]},
    {UndercityCli.Commands.Search, ["search"]},
    {UndercityCli.Commands.Inventory, ["inventory", "i"]},
    {UndercityCli.Commands.Drop, ["drop"]},
    {UndercityCli.Commands.Eat, ["eat"]},
    {UndercityCli.Commands.Scribble, ["scribble"]}
  ]

  @commands Map.new(
              Enum.flat_map(@command_routes, fn {mod, verbs} ->
                Enum.map(verbs, &{&1, mod})
              end)
            )

  def dispatch(input, state, gateway, message_buffer) do
    parsed = split(input)

    case Map.get(@commands, verb(parsed)) do
      nil ->
        message_buffer.warn(
          "Unknown command. Try: search, inventory, drop [n], eat [n], scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit"
        )

        GameState.continue(state)

      module ->
        module.dispatch(parsed, state, gateway, message_buffer)
    end
  end

  def handle_action({:error, :exhausted}, state, message_buffer, _callback) do
    message_buffer.warn("You are too exhausted to act.")
    GameState.continue(state)
  end

  def handle_action({:error, :collapsed}, state, message_buffer, _callback) do
    message_buffer.warn("Your body has given out.")
    GameState.continue(state)
  end

  def handle_action({:error, :not_in_block}, state, message_buffer, _callback) do
    message_buffer.warn("You can't do that from here.")
    GameState.continue(state)
  end

  def handle_action(result, _state, _message_buffer, callback), do: callback.(result)

  defp split(input) do
    case String.split(input, " ", parts: 2) do
      [verb] -> verb
      [verb, rest] -> {verb, rest}
    end
  end

  defp verb({verb, _rest}), do: verb
  defp verb(verb), do: verb
end
