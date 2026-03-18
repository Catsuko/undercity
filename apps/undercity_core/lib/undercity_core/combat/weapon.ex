defmodule UndercityCore.Combat.Weapon do
  @moduledoc """
  Weapon registry and lookup functions.

  Weapons are regular `Item`s whose names appear in this registry.
  The registry maps item names to combat stats used for hit/damage resolution.
  The `Item` struct is unchanged — weapon-ness is determined by name lookup.
  """

  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityCore.Item.Catalogue

  @type stats :: %{
          damage_min: pos_integer(),
          damage_max: pos_integer(),
          hit_modifier: float()
        }

  @registry %{
    iron_pipe: %{damage_min: 2, damage_max: 6, hit_modifier: 0.0}
  }

  @registry_by_name Map.new(@registry, fn {id, s} -> {Catalogue.name!(id), s} end)

  @doc """
  Returns combat stats for the named weapon, or `:not_a_weapon` if the name
  is not in the registry.
  """
  @spec stats(String.t()) :: {:ok, stats()} | :not_a_weapon
  def stats(name) when is_binary(name) do
    case Map.fetch(@registry_by_name, name) do
      {:ok, s} -> {:ok, s}
      :error -> :not_a_weapon
    end
  end

  @doc """
  Returns `true` if the given item name is a registered weapon.
  """
  @spec weapon?(String.t()) :: boolean()
  def weapon?(name) when is_binary(name), do: Map.has_key?(@registry_by_name, name)

  @doc """
  Returns the catalogue atom ids of all registered weapons.
  """
  @spec all_ids() :: [atom()]
  def all_ids, do: Map.keys(@registry)

  @doc """
  Finds the first weapon in the given inventory.
  Returns `{:ok, item}` or `:none`.
  """
  @spec find_in_inventory(Inventory.t()) :: {:ok, Item.t()} | :none
  def find_in_inventory(%Inventory{} = inventory) do
    case Enum.find(Inventory.list_items(inventory), fn item -> weapon?(item.name) end) do
      nil -> :none
      item -> {:ok, item}
    end
  end
end
