defmodule UndercityServer.Actions.Attack do
  @moduledoc """
  Handles the attack action.

  Validates the target and weapon before spending AP, then resolves combat
  and applies damage to the target.
  """

  alias UndercityCore.Combat
  alias UndercityCore.Combat.Weapon
  alias UndercityServer.Block
  alias UndercityServer.Player

  def attack(player_id, block_id, target_id, weapon_index) do
    with :ok <- validate_target(player_id, block_id, target_id),
         {:ok, item} <- find_weapon(player_id, weapon_index),
         {:ok, stats} <- weapon_stats(item.name) do
      Player.perform(player_id, fn -> resolve_attack(target_id, item.name, stats) end)
    end
  end

  defp validate_target(player_id, _block_id, player_id), do: {:error, :invalid_target}

  defp validate_target(_player_id, block_id, target_id) do
    if Block.has_person?(block_id, target_id), do: :ok, else: {:error, :invalid_target}
  end

  defp find_weapon(player_id, index) do
    case player_id |> Player.check_inventory() |> Enum.at(index) do
      nil -> {:error, :invalid_weapon}
      item -> {:ok, item}
    end
  end

  defp weapon_stats(name) do
    case Weapon.stats(name) do
      {:ok, _} = ok -> ok
      :not_a_weapon -> {:error, :invalid_weapon}
    end
  end

  defp resolve_attack(target_id, weapon_name, weapon_stats) do
    case Combat.resolve(weapon_stats) do
      {:hit, damage} ->
        case Player.take_damage(target_id, damage) do
          {:ok, _hp} -> {:hit, target_id, weapon_name, damage}
          {:error, :collapsed} -> {:miss, target_id}
        end

      :miss ->
        {:miss, target_id}
    end
  end
end
