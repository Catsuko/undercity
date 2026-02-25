defmodule UndercityCli.Commands.Attack do
  @moduledoc """
  Handles the attack command.

  Supports a full selection pipeline:
  - `attack` → target selector → weapon selector → dispatch
  - `attack <target>` → weapon selector → dispatch
  - `attack <target> <n>` → dispatch directly (n is the 1-based weapon index)
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.View.InventorySelector
  alias UndercityCli.View.TargetSelector

  def usage, do: "attack [target] [n]"

  def dispatch(
        command,
        state,
        gateway,
        message_buffer,
        inventory_selector \\ InventorySelector,
        target_selector \\ TargetSelector
      )

  def dispatch("attack", state, gateway, message_buffer, inventory_selector, target_selector) do
    case target_selector.select(Map.get(state.vicinity, :people), "Attack who?") do
      {:ok, target} -> attack(target.name, state, gateway, message_buffer, inventory_selector)
      :cancel -> handle_outcome(:cancel, state, message_buffer)
    end
  end

  def dispatch({"attack", rest}, state, gateway, message_buffer, inventory_selector, _target_selector) do
    case parse_rest(rest) do
      {:target, target_name} ->
        attack(target_name, state, gateway, message_buffer, inventory_selector)

      {:target_and_index, target_name, weapon_index} ->
        attack(target_name, weapon_index, state, gateway, message_buffer)
    end
  end

  # Pipeline step 1: target known by name, weapon not yet selected
  defp attack(target_name, %GameState{} = state, gateway, message_buffer, inventory_selector) do
    case state.player_id |> gateway.check_inventory() |> inventory_selector.select("Attack with what?") do
      {:ok, index} -> attack(target_name, index, state, gateway, message_buffer)
      :cancel -> handle_outcome(:cancel, state, message_buffer)
    end
  end

  # Pipeline step 2: target and weapon known, execute the attack
  defp attack(target_name, index, %GameState{} = state, gateway, message_buffer) do
    case find_target_id(Map.get(state.vicinity, :people), target_name) do
      {:ok, target_id} ->
        state.player_id
        |> gateway.perform(state.vicinity.id, :attack, {target_id, index})
        |> Commands.handle_action(state, message_buffer, &handle_outcome(&1, state, message_buffer))

      {:error, _} = error ->
        handle_outcome(error, state, message_buffer)
    end
  end

  defp find_target_id(people, name) do
    case Enum.find(people || [], fn p -> p.name == name end) do
      nil -> {:error, :invalid_target}
      target -> {:ok, target.id}
    end
  end

  defp handle_outcome(:cancel, state, _message_buffer), do: GameState.continue(state)

  defp handle_outcome({:ok, {outcome, target_id, weapon_name, damage}, new_ap}, state, message_buffer)
       when outcome in [:hit, :collapsed] do
    target_name = find_target_name(Map.get(state.vicinity, :people), target_id)
    message_buffer.success("You attack #{target_name} with #{weapon_name} and do #{damage} damage.")
    GameState.continue(state, new_ap, state.hp)
  end

  defp handle_outcome({:ok, {:miss, target_id}, new_ap}, state, message_buffer) do
    target_name = find_target_name(Map.get(state.vicinity, :people), target_id)
    message_buffer.warn("You attack #{target_name} and miss.")
    GameState.continue(state, new_ap, state.hp)
  end

  defp handle_outcome({:error, :invalid_weapon}, state, message_buffer) do
    message_buffer.warn("You can't attack with that.")
    GameState.continue(state)
  end

  defp handle_outcome({:error, :invalid_target}, state, message_buffer) do
    message_buffer.warn("You miss.")
    GameState.continue(state)
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
