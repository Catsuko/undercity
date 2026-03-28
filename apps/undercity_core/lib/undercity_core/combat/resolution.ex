defmodule UndercityCore.Combat.Resolution do
  @moduledoc """
  Low-level combat dice rolls.

  Pure functions for determining whether an attack hits and how much damage
  it deals. Takes weapon stats from `Combat.Weapon`; returns result tuples
  consumed by `Combat.resolve/3`.
  """

  alias UndercityCore.Combat.Weapon

  @base_hit_chance 0.65

  @doc """
  Returns true if an attack with the given weapon stats lands.

  - Roll is checked against base hit chance (0.65) plus `hit_modifier`
  - `roll` is optional (0.0–1.0); defaults to `:rand.uniform/0` for testability
  """
  @spec hit?(Weapon.stats(), float()) :: boolean()
  def hit?(weapon_stats, roll \\ :rand.uniform()) do
    roll < @base_hit_chance + weapon_stats.hit_modifier
  end

  @doc """
  Returns a damage value within the weapon's `damage_min`–`damage_max` range.

  - `roll` is optional (0.0–1.0); defaults to `:rand.uniform/0` for testability
  """
  @spec roll_damage(Weapon.stats(), float()) :: pos_integer()
  def roll_damage(%{damage_min: damage_min, damage_max: damage_max}, roll \\ :rand.uniform()) do
    min(damage_min + trunc(roll * (damage_max - damage_min + 1)), damage_max)
  end

  @doc """
  Rolls a full attack with the given weapon stats.

  - Returns `{:hit, damage}` or `:miss`
  - `hit_roll` and `damage_roll` are optional (0.0–1.0) for deterministic testing
  """
  @spec roll(Weapon.stats(), float(), float()) :: {:hit, pos_integer()} | :miss
  def roll(weapon_stats, hit_roll \\ :rand.uniform(), damage_roll \\ :rand.uniform()) do
    if hit?(weapon_stats, hit_roll) do
      {:hit, roll_damage(weapon_stats, damage_roll)}
    else
      :miss
    end
  end
end
