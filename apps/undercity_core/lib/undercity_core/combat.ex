defmodule UndercityCore.Combat do
  @moduledoc """
  High-level facade for combat.

  External modules (server layer, actions) should call through here rather
  than reaching into sub-modules directly.
  """

  alias UndercityCore.Combat.Resolution
  alias UndercityCore.Combat.Weapon

  @doc """
  Resolves an attack with the given weapon stats.

  Returns `{:hit, damage}` or `:miss`. Optional `hit_roll` and `damage_roll`
  floats (0.0–1.0) can be supplied for deterministic testing.
  """
  @spec resolve(Weapon.stats(), float(), float()) :: {:hit, pos_integer()} | :miss
  def resolve(weapon_stats, hit_roll \\ :rand.uniform(), damage_roll \\ :rand.uniform()) do
    Resolution.roll(weapon_stats, hit_roll, damage_roll)
  end
end
