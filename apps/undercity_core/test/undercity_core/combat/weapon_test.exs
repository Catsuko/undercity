defmodule UndercityCore.Combat.WeaponTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Combat.Weapon
  alias UndercityCore.Inventory
  alias UndercityCore.Item

  describe "stats/1" do
    test "returns stats for a known weapon" do
      assert {:ok, stats} = Weapon.stats("Iron Pipe")
      assert stats.damage_min == 2
      assert stats.damage_max == 6
      assert is_float(stats.hit_modifier)
    end

    test "returns :not_a_weapon for an unknown name" do
      assert :not_a_weapon = Weapon.stats("Chalk")
    end

    test "returns :not_a_weapon for an empty string" do
      assert :not_a_weapon = Weapon.stats("")
    end
  end

  describe "weapon?/1" do
    test "returns true for a registered weapon name" do
      assert Weapon.weapon?("Iron Pipe")
    end

    test "returns false for a non-weapon item name" do
      refute Weapon.weapon?("Junk")
    end

    test "returns false for an empty string" do
      refute Weapon.weapon?("")
    end
  end

  describe "find_in_inventory/1" do
    test "returns :none for an empty inventory" do
      inventory = Inventory.new()
      assert :none = Weapon.find_in_inventory(inventory)
    end

    test "returns :none when inventory has no weapons" do
      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.new("Junk"))
      assert :none = Weapon.find_in_inventory(inventory)
    end

    test "returns {:ok, item} when inventory contains a weapon" do
      iron_pipe = Item.new("Iron Pipe")
      {:ok, inventory} = Inventory.add_item(Inventory.new(), iron_pipe)
      assert {:ok, ^iron_pipe} = Weapon.find_in_inventory(inventory)
    end

    test "returns the first weapon when inventory has multiple weapons" do
      first = Item.new("Iron Pipe")
      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.new("Junk"))
      {:ok, inventory} = Inventory.add_item(inventory, first)

      assert {:ok, ^first} = Weapon.find_in_inventory(inventory)
    end
  end
end
