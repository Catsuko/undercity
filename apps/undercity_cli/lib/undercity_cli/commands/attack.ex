defmodule UndercityCli.Commands.Attack do
  @moduledoc """
  Handles the attack command.

  Supports a full selection pipeline:
  - `attack` → target overlay → weapon overlay → execute
  - `attack <target>` → weapon overlay → execute
  - `attack <target> <n>` → execute directly (n is the 1-based weapon index)

  Selection confirm stages (routed via Commands.dispatch/3):
  - `{"attack", target_idx}` when integer → resolve target, show weapon overlay
  - `{"attack", target_name, weapon_idx}` → execute
  """

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Selection
  alias UndercityCli.MessageBuffer

  def usage, do: "attack [target] [n]"

  # Bare "attack" — set up target selection from vicinity
  def dispatch(verb, state) when is_binary(verb) do
    Selection.from_people(state, verb, "There is no one else here.", "Attack who?")
  end

  # Typed "attack goblin" or "attack goblin 1" — tokenize and dispatch
  def dispatch({verb, rest}, state) when is_binary(rest) do
    case String.split(rest, " ", parts: 2) do
      [name] ->
        show_weapon_overlay(verb, name, state)

      [name, weapon_index] ->
        case Integer.parse(weapon_index) do
          {n, ""} when n >= 1 -> dispatch({verb, name, n - 1}, state)
          _ -> show_weapon_overlay(verb, name, state)
        end
    end
  end

  # Re-dispatch after target overlay — resolve index, show weapon selector
  def dispatch({verb, target_idx}, state) when is_integer(target_idx) do
    person = Enum.at(state.vicinity.people, target_idx)
    show_weapon_overlay(verb, person.name, state)
  end

  # Canonical fully-specified form — execute the attack
  def dispatch({_verb, target_name, weapon_idx}, state) when is_integer(weapon_idx) do
    case find_person(state.vicinity.people, target_name) do
      {:ok, person} ->
        state.player_id
        |> state.gateway.perform(state.vicinity.id, :attack, {person.id, weapon_idx, state.player_name})
        |> Commands.handle_action(state, &handle_outcome(&1, &2, target_name))

      {:error, :invalid_target} ->
        MessageBuffer.warn("You miss.")
        state
    end
  end

  defp show_weapon_overlay(verb, target_name, state) do
    Selection.from_inventory(state, verb, [target_name], "You have nothing to attack with.", "Attack with what?")
  end

  defp handle_outcome({:ok, {:hit, _target_id, weapon_name, damage}, new_ap}, state, target_name) do
    MessageBuffer.success("You attack #{target_name} with #{weapon_name} and do #{damage} damage.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:ok, {:miss, _target_id}, new_ap}, state, target_name) do
    MessageBuffer.warn("You attack #{target_name} and miss.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:error, :invalid_weapon}, state, _target_name) do
    MessageBuffer.warn("You can't attack with that.")
    state
  end

  defp find_person(people, name) do
    case Enum.find(people || [], fn p -> p.name == name end) do
      nil -> {:error, :invalid_target}
      person -> {:ok, person}
    end
  end
end
