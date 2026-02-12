defmodule UndercityCore.SearchTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityCore.Search

  describe "search/2" do
    test "returns {:found, item, inventory} when roll is below threshold" do
      inventory = Inventory.new()

      assert {:found, %Item{name: "Junk"}, updated} = Search.search(inventory, 0.05)
      assert Inventory.size(updated) == 1
    end

    test "returns :nothing when roll is above threshold" do
      inventory = Inventory.new()

      assert :nothing = Search.search(inventory, 0.5)
    end

    test "returns :nothing when roll is exactly at threshold" do
      inventory = Inventory.new()

      assert :nothing = Search.search(inventory, 0.1)
    end

    test "returns :nothing when inventory is full even on successful roll" do
      inventory =
        Enum.reduce(1..5, Inventory.new(), fn _, inv ->
          Inventory.add_item(inv, Item.new("Junk"))
        end)

      assert :nothing = Search.search(inventory, 0.05)
    end
  end
end
