defmodule UndercityCli.Commands.Attack do
  @moduledoc """
  Handles the attack command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState
  alias UndercityCli.View.InventorySelector

  def usage, do: "attack <player>"

  def dispatch(command, state, gateway, message_buffer, selector \\ InventorySelector)

  def dispatch("attack", state, _gateway, message_buffer, _selector) do
    message_buffer.warn("Attack who?")
    GameState.continue(state)
  end

  def dispatch({"attack", target_name}, state, gateway, message_buffer, selector) do
    case find_target(state.vicinity.people, target_name) do
      :not_found ->
        message_buffer.warn("#{target_name} is not here.")
        GameState.continue(state)

      {:ok, %{id: id}} when id == state.player_id ->
        message_buffer.warn("You can't attack yourself.")
        GameState.continue(state)

      {:ok, target} ->
        case select_from_inventory(state, gateway, selector) do
          :cancel -> GameState.continue(state)
          {:ok, index} -> attack(target, index, state, gateway, message_buffer)
        end
    end
  end

  defp attack(target, index, state, gateway, message_buffer) do
    state.player_id
    |> gateway.perform(state.vicinity.id, :attack, {target.id, index})
    |> Commands.handle_action(state, message_buffer, fn
      {:ok, {outcome, target_name, weapon_name, damage}, new_ap} when outcome in [:hit, :collapsed] ->
        message_buffer.success("You strike #{target_name} with #{weapon_name} for #{damage} damage.")
        GameState.continue(state, new_ap, state.hp)

      {:ok, {:miss, target_name}, new_ap} ->
        message_buffer.warn("You swing at #{target_name} but miss.")
        GameState.continue(state, new_ap, state.hp)

      {:error, :invalid_weapon} ->
        message_buffer.warn("You can't attack with that.")
        GameState.continue(state)
    end)
  end

  defp select_from_inventory(state, gateway, selector) do
    state.player_id
    |> gateway.check_inventory()
    |> selector.select("Attack with which weapon?")
  end

  defp find_target(people, target_name) do
    case Enum.find(people, fn p -> p.name == target_name end) do
      nil -> :not_found
      person -> {:ok, person}
    end
  end
end
