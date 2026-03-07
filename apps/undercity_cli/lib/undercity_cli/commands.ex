defmodule UndercityCli.Commands do
  @moduledoc """
  Routes parsed input to the appropriate command module.

  `dispatch/1` is the single entry point for all dispatch — both fresh input
  and post-selection re-dispatch. App always calls this function regardless of
  whether a selection just happened.

  ## Dispatch convention

  When a command needs user selection it sets `state.pending` with:
  - `command` — the verb used for routing on the next dispatch
  - `args` — resolved values accumulated from previous selections

  On each selection confirm, App appends the raw cursor index to `pending.args`
  and calls `dispatch/1` again. Commands reconstructs the canonical parsed form
  via `List.to_tuple([command | args])` and calls the module with a cleared
  pending state.

  Command modules must follow this pattern:
  - `dispatch(verb, state)` — bare command, show selector, set pending
  - `dispatch({verb, arg_str}, state)` — dumb string parser, delegates to typed form
  - `dispatch({verb, arg}, state)` — typed/canonical form, contains real logic

  Multi-stage commands (e.g. Attack) add extra clauses for each intermediate
  stage, pattern matching on the tuple shape. `pending.args` always holds
  resolved values (e.g. target name), never raw indices from prior stages.

  `handle_action/3` is a shared helper used by command modules to normalise
  Gateway results — catching exhaustion/collapse before delegating to the
  command-specific callback.
  """

  alias UndercityCli.MessageBuffer
  alias UndercityCli.State

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

  def dispatch(%{pending: nil} = state) do
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

  def dispatch(%{pending: %{command: command, args: args}} = state) do
    module = Map.fetch!(@commands, command)
    parsed = reconstruct(command, args)
    module.dispatch(parsed, State.clear_pending(state))
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
