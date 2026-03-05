defmodule UndercityCli.Commands do
  @moduledoc """
  Routes parsed input to the appropriate command module.

  Splits raw input into a verb (and optional rest), looks up the verb in the
  routing table, and delegates to the matching command module. Each command
  module takes and returns a State.

  Also exposes `redispatch/3` for App to use after a selection overlay is
  confirmed — routes directly to the right command dispatch variant with the
  accumulated args.

  `handle_action/3` is a shared helper used by command modules to normalise
  Gateway results — catching exhaustion/collapse before delegating to the
  command-specific callback.
  """

  alias UndercityCli.MessageBuffer

  @command_routes [
    {UndercityCli.Commands.Move, ["north", "south", "east", "west", "n", "s", "e", "w", "enter", "exit"]},
    {UndercityCli.Commands.Search, ["search"]},
    {UndercityCli.Commands.Inventory, ["inventory", "i"]},
    {UndercityCli.Commands.Drop, ["drop"]},
    {UndercityCli.Commands.Eat, ["eat"]},
    {UndercityCli.Commands.Scribble, ["scribble"]},
    {UndercityCli.Commands.Attack, ["attack"]},
    {UndercityCli.Commands.Help, ["help"]}
  ]

  @commands Map.new(
              Enum.flat_map(@command_routes, fn {mod, verbs} ->
                Enum.map(verbs, &{&1, mod})
              end)
            )

  def usage_hints do
    @command_routes
    |> Enum.map(fn {mod, _verbs} -> mod.usage() end)
    |> Enum.sort()
    |> Enum.join("\n")
  end

  def dispatch(input, state) do
    parsed = split(input)

    case Map.get(@commands, verb(parsed)) do
      nil ->
        MessageBuffer.warn("Unknown command. Type 'help' for a list of commands.")
        state

      module ->
        module.dispatch(parsed, state)
    end
  end

  @doc """
  Re-dispatches to a command module after a selection overlay is confirmed.
  `command` is the verb, `args` is the full accumulated arg list including
  the newly chosen 0-based index.
  """
  def redispatch(command, args, state) do
    module = Map.fetch!(@commands, command)
    apply(module, :dispatch, [command | args] ++ [state])
  end

  def handle_action({:error, :exhausted}, state, _callback) do
    MessageBuffer.warn("You are too exhausted to act.")
    state
  end

  def handle_action({:error, :collapsed}, state, _callback) do
    MessageBuffer.warn("Your body has given out.")
    state
  end

  def handle_action({:error, :not_in_block}, state, _callback) do
    MessageBuffer.warn("You can't do that from here.")
    state
  end

  def handle_action(result, state, callback), do: callback.(result, state)

  defp split(input) do
    case String.split(input, " ", parts: 2) do
      [verb] -> verb
      [verb, rest] -> {verb, rest}
    end
  end

  defp verb({verb, _rest}), do: verb
  defp verb(verb), do: verb
end
