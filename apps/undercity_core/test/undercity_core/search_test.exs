defmodule UndercityCore.SearchTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityCore.Search

  describe "search/2" do
    test "returns {:found, item} when roll is below threshold" do
      loot_table = [{0.10, "Junk"}]

      assert {:found, %Item{name: "Junk"}} = Search.search(loot_table, 0.05)
    end

    test "returns :nothing when roll is above threshold" do
      loot_table = [{0.10, "Junk"}]

      assert :nothing = Search.search(loot_table, 0.5)
    end

    test "returns :nothing when roll is exactly at threshold" do
      loot_table = [{0.10, "Junk"}]

      assert :nothing = Search.search(loot_table, 0.1)
    end

    test "selects the correct item from a multi-entry table" do
      loot_table = [{0.20, "Chalk"}, {0.05, "Junk"}]

      assert {:found, %Item{name: "Chalk"}} = Search.search(loot_table, 0.10)
      assert {:found, %Item{name: "Junk"}} = Search.search(loot_table, 0.22)
      assert :nothing = Search.search(loot_table, 0.30)
    end
  end
end
