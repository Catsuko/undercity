defmodule UndercityServer.PlayerTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityServer.Player

  setup do
    id = "player_#{:rand.uniform(100_000)}"
    name = "test_#{id}"

    start_supervised!({Player, id: id, name: name}, id: id)

    on_exit(fn ->
      path = Path.join([File.cwd!(), "data", "players", "players.dets"])
      File.rm(path)
    end)

    %{id: id}
  end

  describe "use_item/2" do
    test "decrements uses on a consumable item", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 3))
      # Small sleep to ensure cast completes before call
      Process.sleep(10)

      assert {:ok, %Item{name: "Chalk", uses: 2}} = Player.use_item(id, "Chalk")

      items = Player.get_inventory(id)
      assert [%Item{name: "Chalk", uses: 2}] = items
    end

    test "removes item when last use is spent", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 1))
      Process.sleep(10)

      assert {:ok, %Item{name: "Chalk", uses: 1}} = Player.use_item(id, "Chalk")

      assert [] = Player.get_inventory(id)
    end

    test "returns :not_found when item is not in inventory", %{id: id} do
      assert :not_found = Player.use_item(id, "Chalk")
    end

    test "non-consumable items are not removed", %{id: id} do
      Player.add_item(id, Item.new("Junk"))
      Process.sleep(10)

      assert {:ok, %Item{name: "Junk", uses: nil}} = Player.use_item(id, "Junk")

      items = Player.get_inventory(id)
      assert [%Item{name: "Junk"}] = items
    end
  end
end
