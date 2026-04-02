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
      item = Item.build(:junk)

      assert {:ok, inventory} = Inventory.add_item(inventory, item)

      assert Inventory.list_items(inventory) == [item]
      assert Inventory.size(inventory) == 1
    end

    test "preserves insertion order" do
      inventory = Inventory.new()
      junk = Item.build(:junk)
      pipe = Item.build(:iron_pipe)

      {:ok, inventory} = Inventory.add_item(inventory, junk)
      {:ok, inventory} = Inventory.add_item(inventory, pipe)

      assert Inventory.list_items(inventory) == [junk, pipe]
    end

    test "returns error when inventory is full" do
      junk = Item.build(:junk)

      inventory =
        Enum.reduce(1..15, Inventory.new(), fn _, inv ->
          {:ok, inv} = Inventory.add_item(inv, junk)
          inv
        end)

      assert Inventory.full?(inventory)
      assert Inventory.size(inventory) == 15

      assert {:error, :full} = Inventory.add_item(inventory, Item.build(:junk))
    end
  end

  describe "find_item/2" do
    test "finds the first item by name" do
      chalk = Item.build(:chalk)

      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.build(:junk))
      {:ok, inventory} = Inventory.add_item(inventory, chalk)

      assert {:ok, ^chalk, 1} = Inventory.find_item(inventory, "Chalk")
    end

    test "returns :not_found when item is not in inventory" do
      inventory = Inventory.new()

      assert :not_found = Inventory.find_item(inventory, "Chalk")
    end
  end

  describe "replace_at/3" do
    test "replaces the item at the given index" do
      chalk = Item.build(:chalk)
      used_chalk = Item.build(:chalk, 4)

      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.build(:junk))
      {:ok, inventory} = Inventory.add_item(inventory, chalk)

      inventory = Inventory.replace_at(inventory, 1, used_chalk)

      assert {:ok, ^used_chalk, 1} = Inventory.find_item(inventory, "Chalk")
    end
  end

  describe "remove_at/2" do
    test "removes the item at the given index" do
      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.build(:junk))
      {:ok, inventory} = Inventory.add_item(inventory, Item.build(:chalk))

      inventory = Inventory.remove_at(inventory, 1)

      assert Inventory.size(inventory) == 1
      assert :not_found = Inventory.find_item(inventory, "Chalk")
    end
  end

  describe "use_item/2" do
    test "decrements uses on a consumable item" do
      chalk = Item.build(:chalk)
      {:ok, inventory} = Inventory.add_item(Inventory.new(), chalk)

      assert {:ok, inventory} = Inventory.use_item(inventory, :chalk)

      assert [%Item{id: :chalk, uses: 4}] = Inventory.list_items(inventory)
    end

    test "removes item when last use is spent" do
      chalk = Item.build(:chalk, 1)
      {:ok, inventory} = Inventory.add_item(Inventory.new(), chalk)

      assert {:ok, inventory} = Inventory.use_item(inventory, :chalk)

      assert [] = Inventory.list_items(inventory)
    end

    test "does not remove a non-consumable item" do
      pipe = Item.build(:iron_pipe)
      {:ok, inventory} = Inventory.add_item(Inventory.new(), pipe)

      assert {:ok, inventory} = Inventory.use_item(inventory, :iron_pipe)

      assert [%Item{id: :iron_pipe}] = Inventory.list_items(inventory)
    end

    test "returns :item_missing for an empty inventory" do
      assert {:error, :item_missing} = Inventory.use_item(Inventory.new(), :chalk)
    end

    test "returns :item_missing when item not in inventory" do
      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.build(:junk))

      assert {:error, :item_missing} = Inventory.use_item(inventory, :chalk)
    end

    test "uses first matching item by id" do
      chalk = Item.build(:chalk, 3)
      {:ok, inventory} = Inventory.add_item(Inventory.new(), Item.build(:junk))
      {:ok, inventory} = Inventory.add_item(inventory, chalk)

      assert {:ok, inventory} = Inventory.use_item(inventory, :chalk)

      items = Inventory.list_items(inventory)
      assert length(items) == 2
      assert %Item{id: :chalk, uses: 2} = Enum.at(items, 1)
    end
  end

  describe "full?/1" do
    test "returns false when under capacity" do
      inventory = Inventory.new()
      refute Inventory.full?(inventory)
    end

    test "returns true when at capacity" do
      inventory =
        Enum.reduce(1..15, Inventory.new(), fn _, inv ->
          {:ok, inv} = Inventory.add_item(inv, Item.build(:junk))
          inv
        end)

      assert Inventory.full?(inventory)
    end
  end
end
