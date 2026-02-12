defmodule UndercityCore.LootTableTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityCore.LootTable

  describe "for_block_type/1" do
    test "returns plaza loot table for :square" do
      table = LootTable.for_block_type(:square)

      assert [{0.20, {"Chalk", 5}}, {0.05, "Junk"}] = table
    end

    test "returns default loot table for other types" do
      assert [{0.10, "Junk"}] = LootTable.for_block_type(:street)
      assert [{0.10, "Junk"}] = LootTable.for_block_type(:fountain)
      assert [{0.10, "Junk"}] = LootTable.for_block_type(:graveyard)
    end
  end

  describe "roll/2" do
    test "returns {:found, item} when roll hits first entry" do
      table = [{0.20, {"Chalk", 5}}, {0.05, "Junk"}]

      assert {:found, %Item{name: "Chalk", uses: 5}} = LootTable.roll(table, 0.10)
    end

    test "returns {:found, item} when roll hits second entry" do
      table = [{0.20, {"Chalk", 5}}, {0.05, "Junk"}]

      assert {:found, %Item{name: "Junk", uses: nil}} = LootTable.roll(table, 0.22)
    end

    test "returns :nothing when roll exceeds all entries" do
      table = [{0.20, {"Chalk", 5}}, {0.05, "Junk"}]

      assert :nothing = LootTable.roll(table, 0.30)
    end

    test "returns :nothing for empty table" do
      assert :nothing = LootTable.roll([], 0.05)
    end
  end
end
