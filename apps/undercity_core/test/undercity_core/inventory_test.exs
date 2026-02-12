defmodule UndercityCore.InventoryTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Inventory
  alias UndercityCore.Item

  describe "new/0" do
    test "creates an empty inventory" do
      inventory = Inventory.new()

      assert Inventory.list_items(inventory) == []
      assert Inventory.size(inventory) == 0
      refute Inventory.full?(inventory)
    end
  end

  describe "add_item/2" do
    test "adds an item to the inventory" do
      inventory = Inventory.new()
      item = Item.new("Junk")

      inventory = Inventory.add_item(inventory, item)

      assert Inventory.list_items(inventory) == [item]
      assert Inventory.size(inventory) == 1
    end

    test "preserves insertion order" do
      inventory = Inventory.new()
      junk = Item.new("Junk")
      bone = Item.new("Bone")

      inventory =
        inventory
        |> Inventory.add_item(junk)
        |> Inventory.add_item(bone)

      assert Inventory.list_items(inventory) == [junk, bone]
    end

    test "does nothing when inventory is full" do
      inventory = Inventory.new()
      junk = Item.new("Junk")

      inventory =
        Enum.reduce(1..5, inventory, fn _, inv ->
          Inventory.add_item(inv, junk)
        end)

      assert Inventory.full?(inventory)
      assert Inventory.size(inventory) == 5

      inventory = Inventory.add_item(inventory, Item.new("Extra"))

      assert Inventory.size(inventory) == 5
    end
  end

  describe "find_item/2" do
    test "finds the first item by name" do
      chalk = Item.new("Chalk", 5)

      inventory =
        Inventory.new()
        |> Inventory.add_item(Item.new("Junk"))
        |> Inventory.add_item(chalk)

      assert {:ok, ^chalk, 1} = Inventory.find_item(inventory, "Chalk")
    end

    test "returns :not_found when item is not in inventory" do
      inventory = Inventory.new()

      assert :not_found = Inventory.find_item(inventory, "Chalk")
    end
  end

  describe "replace_at/3" do
    test "replaces the item at the given index" do
      chalk = Item.new("Chalk", 5)
      used_chalk = Item.new("Chalk", 4)

      inventory =
        Inventory.new()
        |> Inventory.add_item(Item.new("Junk"))
        |> Inventory.add_item(chalk)

      inventory = Inventory.replace_at(inventory, 1, used_chalk)

      assert {:ok, ^used_chalk, 1} = Inventory.find_item(inventory, "Chalk")
    end
  end

  describe "remove_at/2" do
    test "removes the item at the given index" do
      inventory =
        Inventory.new()
        |> Inventory.add_item(Item.new("Junk"))
        |> Inventory.add_item(Item.new("Chalk", 5))

      inventory = Inventory.remove_at(inventory, 1)

      assert Inventory.size(inventory) == 1
      assert :not_found = Inventory.find_item(inventory, "Chalk")
    end
  end

  describe "full?/1" do
    test "returns false when under capacity" do
      inventory = Inventory.new()
      refute Inventory.full?(inventory)
    end

    test "returns true when at capacity" do
      inventory =
        Enum.reduce(1..5, Inventory.new(), fn _, inv ->
          Inventory.add_item(inv, Item.new("Junk"))
        end)

      assert Inventory.full?(inventory)
    end
  end
end
