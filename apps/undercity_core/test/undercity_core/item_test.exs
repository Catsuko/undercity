defmodule UndercityCore.ItemTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item

  describe "build/1" do
    test "builds an item with the catalogue name and default uses" do
      chalk = Item.build(:chalk)
      assert chalk.id == :chalk
      assert chalk.name == "Chalk"
      assert chalk.uses == 5
    end

    test "builds a non-consumable item with nil uses" do
      pipe = Item.build(:iron_pipe)
      assert pipe.id == :iron_pipe
      assert pipe.name == "Iron Pipe"
      assert pipe.uses == nil
    end

    test "sets catalogue id on the struct" do
      assert %Item{id: :mushroom} = Item.build(:mushroom)
    end
  end

  describe "build/2" do
    test "overrides the default use count" do
      chalk = Item.build(:chalk, 2)
      assert chalk.uses == 2
    end

    test "allows nil to fall back to catalogue default" do
      chalk = Item.build(:chalk, nil)
      assert chalk.uses == 5
    end
  end

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
