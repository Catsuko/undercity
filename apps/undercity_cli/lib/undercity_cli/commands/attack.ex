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
  alias UndercityCli.MessageBuffer
  alias UndercityCli.State

  def usage, do: "attack [target] [n]"

  # Bare "attack" — set up target selection from vicinity
  def dispatch("attack", state) do
    case state.vicinity.people do
      nil ->
        MessageBuffer.warn("There is no one else here.")
        state

      [] ->
        MessageBuffer.warn("There is no one else here.")
        state

      people ->
        state
        |> State.pending("attack", [])
        |> State.select("Attack who?", people)
    end
  end

  # Typed "attack goblin" or "attack goblin 1" — parse and delegate to canonical form
  def dispatch({"attack", rest}, state) when is_binary(rest) do
    case parse_rest(rest) do
      {:target, target_name} ->
        attack_with_target(target_name, state)

      {:target_and_index, target_name, weapon_index} ->
        dispatch({"attack", target_name, weapon_index}, state)
    end
  end

  # Re-dispatch after target overlay — resolve index, show weapon selector
  def dispatch({"attack", target_idx}, state) when is_integer(target_idx) do
    person = Enum.at(state.vicinity.people, target_idx)
    attack_with_target(person.name, state)
  end

  # Canonical fully-specified form — execute the attack
  def dispatch({"attack", target_name, weapon_idx}, state) do
    case find_target_id(state.vicinity.people, target_name) do
      {:ok, target_id} ->
        state.player_id
        |> state.gateway.perform(state.vicinity.id, :attack, {target_id, weapon_idx, state.player_name})
        |> Commands.handle_action(state, &handle_outcome/2)

      {:error, _} ->
        MessageBuffer.warn("You miss.")
        state
    end
  end

  defp attack_with_target(target_name, state) do
    case state.gateway.check_inventory(state.player_id) do
      [] ->
        MessageBuffer.warn("You have nothing to attack with.")
        state

      items ->
        state
        |> State.pending("attack", [target_name])
        |> State.select("Attack with what?", items)
    end
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
