defmodule UndercityCli.Commands.Attack do
  @moduledoc """
  Handles the attack command.

  Supports a full selection pipeline:
  - `attack` → target overlay → weapon overlay → execute
  - `attack <target>` → weapon overlay → execute
  - `attack <target> <n>` → execute directly (n is the 1-based weapon index)

  Re-dispatch stages (via Commands.dispatch/1 pending reconstruction):
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

  # Typed "attack goblin" or "attack goblin 1" — parse and delegate to canonical form
  def dispatch({verb, rest}, state) when is_binary(rest) do
    case parse_rest(rest) do
      {:target, target_name} -> select_weapon(verb, target_name, state)
      {:target_and_index, target_name, weapon_index} -> dispatch({verb, target_name, weapon_index}, state)
    end
  end

  # Re-dispatch after target overlay — resolve index, show weapon selector
  def dispatch({verb, target_idx}, state) when is_integer(target_idx) do
    person = Enum.at(state.vicinity.people, target_idx)
    select_weapon(verb, person.name, state)
  end

  # Canonical fully-specified form — execute the attack
  def dispatch({_verb, target_name, weapon_idx}, state) do
    case find_target_id(state.vicinity.people, target_name) do
      {:ok, target_id} ->
        state.player_id
        |> state.gateway.perform(state.vicinity.id, :attack, {target_id, weapon_idx, state.player_name})
        |> Commands.handle_action(state, &handle_outcome/2)

      error ->
        handle_outcome(error, state)
    end
  end

  defp select_weapon(verb, target_name, state) do
    Selection.from_inventory(state, verb, [target_name], "You have nothing to attack with.", "Attack with what?")
  end

  defp handle_outcome({:ok, {:hit, target_id, weapon_name, damage}, new_ap}, state) do
    target_name = find_target_name(state.vicinity.people, target_id)
    MessageBuffer.success("You attack #{target_name} with #{weapon_name} and do #{damage} damage.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:ok, {:miss, target_id}, new_ap}, state) do
    target_name = find_target_name(state.vicinity.people, target_id)
    MessageBuffer.warn("You attack #{target_name} and miss.")
    %{state | ap: new_ap}
  end

  defp handle_outcome({:error, :invalid_weapon}, state) do
    MessageBuffer.warn("You can't attack with that.")
    state
  end

  defp handle_outcome({:error, :invalid_target}, state) do
    MessageBuffer.warn("You miss.")
    state
  end

  defp find_target_id(people, name) do
    case Enum.find(people || [], fn p -> p.name == name end) do
      nil -> {:error, :invalid_target}
      target -> {:ok, target.id}
    end
  end

  defp find_target_name(people, target_id) do
    Enum.find_value(people || [], target_id, fn p -> if p.id == target_id, do: p.name end)
  end

  defp parse_rest(rest) do
    parts = String.split(rest, " ")

    with [_ | _] <- parts,
         last = List.last(parts),
         {n, ""} when n >= 1 <- Integer.parse(last),
         target_parts = Enum.slice(parts, 0..-2//1),
         [_ | _] <- target_parts do
      {:target_and_index, Enum.join(target_parts, " "), n - 1}
    else
      _ -> {:target, rest}
    end
  end
end
