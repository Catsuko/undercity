defmodule UndercityCli.Commands do
  @moduledoc """
  Routes parsed input to the appropriate command module.

  `dispatch/1` is the single entry point for fresh input dispatch. It reads
  `state.input`, parses it, and calls the matching command module.

  `dispatch/3` is used by `Commands.Selection` to route confirmed
  selections directly to a command module, bypassing input parsing.

  Command modules must follow this pattern:
  - `dispatch(verb, state)` — bare command, show selector
  - `dispatch({verb, arg_str}, state)` — dumb string parser, delegates to typed form
  - `dispatch({verb, arg}, state)` — typed/canonical form, contains real logic

  Multi-stage commands (e.g. Attack) add extra clauses for each intermediate
  stage, pattern matching on the tuple shape.

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
    {UndercityCli.Commands.Use, ["use"]},
    {UndercityCli.Commands.Help, ["help"]}
  ]

  @commands Map.new(
              Enum.flat_map(@command_routes, fn {mod, verbs} ->
                Enum.map(verbs, &{&1, mod})
              end)
            )

  @doc """
  Returns a newline-separated string of usage hints for all registered commands, sorted alphabetically.
  """
  def usage_hints do
    @command_routes
    |> Enum.map(fn {mod, _verbs} -> mod.usage() end)
    |> Enum.sort()
    |> Enum.join("\n")
  end

  @doc """
  Dispatches the current input string in `state` to the appropriate command module.

  - Parses `state.input`, clears it, and routes to the matching command via the compile-time verb map.
  - Emits a warning and returns state unchanged if no matching command is found.
  """
  def dispatch(state) do
    parsed = state.input |> String.trim() |> String.downcase() |> split()
    state = %{state | input: ""}

    case Map.get(@commands, verb(parsed)) do
      nil ->
        MessageBuffer.warn("Unknown command. Type 'help' for a list of commands.")
        state

      module ->
        module.dispatch(parsed, state)
    end
  end

  @doc """
  Dispatches a pre-parsed command and argument list directly to its command module.

  - Used by `Commands.Selection` to re-dispatch after a selection overlay is confirmed.
  - `command` must be a registered verb string; raises if not found.
  """
  def dispatch(command, args, state) do
    module = Map.fetch!(@commands, command)
    module.dispatch(reconstruct(command, args), state)
  end

  @doc """
  Normalises a Gateway result, handling shared error cases before delegating to a command-specific callback.

  - `:exhausted` and `:collapsed` emit a warning and return state unchanged without calling `callback`.
  - `:not_in_block` emits a warning and returns state unchanged.
  - All other results are passed to `callback.(result, state)`.
  """
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

  defp reconstruct(command, []), do: command
  defp reconstruct(command, args), do: List.to_tuple([command | args])

  defp split(input) do
    case String.split(input, " ", parts: 2) do
      [verb] -> verb
      [verb, rest] -> {verb, rest}
    end
  end

  defp verb({verb, _rest}), do: verb
  defp verb(verb), do: verb
end
