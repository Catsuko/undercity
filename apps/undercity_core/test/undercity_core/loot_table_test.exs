defmodule UndercityCore.LootTableTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityCore.LootTable

  describe "for_block_type/1 via roll/2" do
    test "square table can yield Chalk" do
      assert {:found, %Item{name: "Chalk", uses: 5}} =
               :square |> LootTable.for_block_type() |> LootTable.roll(0.10)
    end

    test "street table can yield Iron Pipe" do
      assert {:found, %Item{name: "Iron Pipe", uses: nil}} =
               :street |> LootTable.for_block_type() |> LootTable.roll(0.04)
    end

    test "graveyard table can yield Mushroom" do
      assert {:found, %Item{name: "Mushroom", uses: nil}} =
               :graveyard |> LootTable.for_block_type() |> LootTable.roll(0.10)
    end

    test "inn table can yield Iron Pipe" do
      assert {:found, %Item{name: "Iron Pipe", uses: nil}} =
               :inn |> LootTable.for_block_type() |> LootTable.roll(0.20)
    end

    test "unknown block type falls back to default table and can yield Junk" do
      assert {:found, %Item{name: "Junk", uses: nil}} =
               :fountain |> LootTable.for_block_type() |> LootTable.roll(0.05)
    end
  end

  describe "roll/2" do
    test "returns {:found, item} when roll hits first entry" do
      table = [{0.20, :chalk}, {0.05, :junk}]

      assert {:found, %Item{name: "Chalk", uses: 5}} = LootTable.roll(table, 0.10)
    end

    test "returns {:found, item} when roll hits second entry" do
      table = [{0.20, :chalk}, {0.05, :junk}]

      assert {:found, %Item{name: "Junk", uses: nil}} = LootTable.roll(table, 0.22)
    end

    test "returns :nothing when roll exceeds all entries" do
      table = [{0.20, :chalk}, {0.05, :junk}]

      assert :nothing = LootTable.roll(table, 0.30)
    end

    test "returns :nothing for empty table" do
      assert :nothing = LootTable.roll([], 0.05)
    end

    test "returns Iron Pipe from street table" do
      table = LootTable.for_block_type(:street)

      assert {:found, %Item{name: "Iron Pipe", uses: nil}} = LootTable.roll(table, 0.04)
    end

    test "returns Iron Pipe from square table" do
      table = LootTable.for_block_type(:square)

      assert {:found, %Item{name: "Iron Pipe", uses: nil}} = LootTable.roll(table, 0.27)
    end
  end
end
