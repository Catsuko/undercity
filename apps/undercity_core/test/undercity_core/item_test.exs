defmodule UndercityCore.ItemTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item

  describe "new/1" do
    test "creates an item with a name and nil uses" do
      item = Item.new("Junk")

      assert item.name == "Junk"
      assert item.uses == nil
    end
  end

  describe "new/2" do
    test "creates an item with a name and uses" do
      item = Item.new("Chalk", 5)

      assert item.name == "Chalk"
      assert item.uses == 5
    end
  end

  describe "use/1" do
    test "decrements uses on a consumable item" do
      item = Item.new("Chalk", 3)

      assert {:ok, used} = Item.use(item)
      assert used.uses == 2
    end

    test "returns :spent when uses reach 0" do
      item = Item.new("Chalk", 1)

      assert :spent = Item.use(item)
    end

    test "non-consumable items always return {:ok, item}" do
      item = Item.new("Junk")

      assert {:ok, ^item} = Item.use(item)
    end

    test "can use an item down to spent" do
      item = Item.new("Chalk", 3)

      assert {:ok, item} = Item.use(item)
      assert item.uses == 2
      assert {:ok, item} = Item.use(item)
      assert item.uses == 1
      assert :spent = Item.use(item)
    end
  end
end
