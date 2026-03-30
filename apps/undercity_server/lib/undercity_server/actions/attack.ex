defmodule UndercityServer.Actions.Attack do
  @moduledoc """
  Resolves the attack action, applying weapon damage to a target player.

  - Validates the target is present in the block and is not the attacker
  - Validates the weapon exists at the given inventory index and is a known weapon
  - Spends 1 AP via `Player.perform/3` before resolving the hit roll
  - On a hit, casts damage to the target's `Player` GenServer; the target server writes inbox
    notifications to both attacker and target
  - On a miss, writes "You miss." to the attacker's inbox directly
  """

  alias UndercityCore.Combat
  alias UndercityCore.Combat.Weapon
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Inbox, as: PlayerInbox

  @doc """
  Executes an attack from `player_id` against `target_id` using the weapon at `weapon_index`.

  - Returns `{:ok, ap}` on a successful hit or miss.
  - Returns `{:error, :invalid_target}` if `target_id` is not in the block or equals `player_id`.
  - Returns `{:error, :invalid_weapon}` if the index is out of range or the item is not a weapon.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the attacker cannot spend AP.
  """
  def attack(player_id, player_name, block_id, target_id, weapon_index) do
    with :ok <- validate_target(player_id, block_id, target_id),
         {:ok, item} <- find_weapon(player_id, weapon_index),
         {:ok, stats} <- weapon_stats(item.name) do
      do_attack(player_id, player_name, target_id, stats)
    end
  end

  defp do_attack(player_id, player_name, target_id, stats) do
    case Player.perform(player_id, fn ->
           resolve_attack(player_id, player_name, target_id, stats)
         end) do
      {:ok, _, ap} -> {:ok, ap}
      {:error, _} = error -> error
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

  defp resolve_attack(player_id, attacker_name, target_id, weapon_stats) do
    case Combat.resolve(weapon_stats) do
      {:hit, damage} ->
        Player.take_damage(target_id, {player_id, attacker_name, damage})

      :miss ->
        PlayerInbox.warning(player_id, "You miss.")
    end
  end
end
