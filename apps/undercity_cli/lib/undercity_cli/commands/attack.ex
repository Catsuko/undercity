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
    attack(state, gateway, message_buffer, inventory_selector, target_selector)
  end

  def dispatch({"attack", rest}, state, gateway, message_buffer, inventory_selector, _target_selector) do
    case parse_rest(rest) do
      {:target, target_name} ->
        attack(target_name, state, gateway, message_buffer, inventory_selector)

      {:target_and_index, target_name, weapon_index} ->
        attack(target_name, weapon_index, state, gateway, message_buffer)
    end
  end

  defp attack(%GameState{} = state, gateway, message_buffer, inventory_selector, target_selector) do
    case target_selector.select(state.vicinity.people, "Attack who?") do
      :cancel -> GameState.continue(state)
      {:ok, target} -> attack(target.name, state, gateway, message_buffer, inventory_selector)
    end
  end

  defp attack(target_name, %GameState{} = state, gateway, message_buffer, inventory_selector) do
    case state.player_id |> gateway.check_inventory() |> inventory_selector.select("Attack with what?") do
      :cancel -> GameState.continue(state)
      {:ok, index} -> attack(target_name, index, state, gateway, message_buffer)
    end
  end

  defp attack(target_name, index, state, gateway, message_buffer) do
    state.player_id
    |> gateway.perform(state.vicinity.id, :attack, {target_name, index})
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, {outcome, target_name, weapon_name, damage}, new_ap} when outcome in [:hit, :collapsed] ->
        message_buffer.success("You attack #{target_name} with #{weapon_name} and do #{damage} damage.")
        GameState.continue(state, new_ap, state.hp)

      {:miss, target_name, weapon_name} ->
        message_buffer.warn("You attack #{target_name} with #{weapon_name} and miss.")
        GameState.continue(state)

      {:error, :invalid_weapon} ->
        message_buffer.warn("You can't attack with that.")
        GameState.continue(state)
    end)
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
