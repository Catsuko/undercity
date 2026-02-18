defmodule UndercityCore.SearchTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityCore.Search

  describe "search/2" do
    test "returns {:found, item} when roll hits the block's loot table" do
      assert {:found, %Item{name: "Mushroom"}} = Search.search(:graveyard, 0.05)
    end

    test "returns :nothing when roll misses" do
      assert :nothing = Search.search(:graveyard, 0.5)
    end

    test "uses default loot table for unknown block types" do
      assert :nothing = Search.search(:street, 0.5)
    end
  end
end
