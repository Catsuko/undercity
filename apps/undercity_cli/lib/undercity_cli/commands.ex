defmodule UndercityCli.Commands do
  @moduledoc """
  Routes parsed input to the appropriate command module.

  Splits raw input into a verb (and optional rest), looks up the verb in the
  routing table, and delegates to the matching command module. Each command
  module implements `dispatch/5` and returns `{:moved, vicinity, ap, hp}` or
  `{:acted, ap, hp}`. The game loop uses the tag to decide what to re-render.

  Also exposes `handle_action/4`, a shared helper used by command modules to
  normalise Gateway results — catching exhaustion/collapse before delegating
  to the command-specific callback.
  """

  alias UndercityCli.MessageBuffer

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

  def dispatch(input, player_id, vicinity, ap, hp) do
    parsed = split(input)

    case Map.get(@commands, verb(parsed)) do
      nil ->
        MessageBuffer.warn(
          "Unknown command. Try: search, inventory, drop [n], eat [n], scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit"
        )

        {:acted, ap, hp}

      module ->
        module.dispatch(parsed, player_id, vicinity, ap, hp)
    end
  end

  def handle_action({:error, :exhausted}, ap, hp, _callback) do
    MessageBuffer.warn("You are too exhausted to act.")
    {:acted, ap, hp}
  end

  def handle_action({:error, :collapsed}, ap, hp, _callback) do
    MessageBuffer.warn("Your body has given out.")
    {:acted, ap, hp}
  end

  def handle_action(result, _ap, _hp, callback), do: callback.(result)

  defp split(input) do
    case String.split(input, " ", parts: 2) do
      [verb] -> verb
      [verb, rest] -> {verb, rest}
    end
  end

  defp verb({verb, _rest}), do: verb
  defp verb(verb), do: verb
end
