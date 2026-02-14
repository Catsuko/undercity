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

      assert :ok = Player.use_item(id, "Chalk")

      items = Player.get_inventory(id)
      assert [%Item{name: "Chalk", uses: 2}] = items
    end

    test "removes item when last use is spent", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 1))
      Process.sleep(10)

      assert :ok = Player.use_item(id, "Chalk")

      assert [] = Player.get_inventory(id)
    end

    test "returns :not_found when item is not in inventory", %{id: id} do
      assert :not_found = Player.use_item(id, "Chalk")
    end

    test "non-consumable items are not removed", %{id: id} do
      Player.add_item(id, Item.new("Junk"))
      Process.sleep(10)

      assert :ok = Player.use_item(id, "Junk")

      items = Player.get_inventory(id)
      assert [%Item{name: "Junk"}] = items
    end
  end

  describe "use_item/3 (atomic AP + item)" do
    test "spends AP and consumes item atomically", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 3))
      Process.sleep(10)

      assert {:ok, 49} = Player.use_item(id, "Chalk", 1)

      assert [%Item{name: "Chalk", uses: 2}] = Player.get_inventory(id)
      assert 49 = Player.get_ap(id)
    end

    test "removes item on last use", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 1))
      Process.sleep(10)

      assert {:ok, 49} = Player.use_item(id, "Chalk", 1)

      assert [] = Player.get_inventory(id)
    end

    test "returns :exhausted when AP insufficient, item untouched", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 3))
      Process.sleep(10)

      # Drain all AP
      for _ <- 1..50, do: Player.perform(id, fn -> :ok end)

      assert {:error, :exhausted} = Player.use_item(id, "Chalk", 1)

      assert [%Item{name: "Chalk", uses: 3}] = Player.get_inventory(id)
    end

    test "returns :item_missing when item not in inventory, AP untouched", %{id: id} do
      assert {:error, :item_missing} = Player.use_item(id, "Chalk", 1)

      assert 50 = Player.get_ap(id)
    end

    test "spends custom AP cost", %{id: id} do
      Player.add_item(id, Item.new("Chalk", 5))
      Process.sleep(10)

      assert {:ok, 47} = Player.use_item(id, "Chalk", 3)

      assert 47 = Player.get_ap(id)
    end
  end

  describe "get_ap/1" do
    test "new player starts with 50 AP", %{id: id} do
      assert 50 = Player.get_ap(id)
    end
  end

  describe "spend_ap via perform/3" do
    test "spends AP and runs action", %{id: id} do
      assert {:ok, :acted, 49} = Player.perform(id, fn -> :acted end)
      assert 49 = Player.get_ap(id)
    end

    test "spends custom cost", %{id: id} do
      assert {:ok, :ok, 45} = Player.perform(id, 5, fn -> :ok end)
      assert 45 = Player.get_ap(id)
    end

    test "returns exhausted when not enough AP", %{id: id} do
      # Drain all AP
      for _ <- 1..50, do: Player.perform(id, fn -> :ok end)

      assert {:error, :exhausted} = Player.perform(id, fn -> :should_not_run end)
    end

    test "multiple spends accumulate", %{id: id} do
      Player.perform(id, fn -> :ok end)
      Player.perform(id, fn -> :ok end)
      Player.perform(id, fn -> :ok end)
      assert 47 = Player.get_ap(id)
    end

    test "spending exactly remaining AP succeeds", %{id: id} do
      # Drain to 3 AP
      for _ <- 1..47, do: Player.perform(id, fn -> :ok end)
      assert 3 = Player.get_ap(id)

      assert {:ok, :ok, 0} = Player.perform(id, 3, fn -> :ok end)
      assert 0 = Player.get_ap(id)
    end

    test "spending one more than remaining AP fails", %{id: id} do
      for _ <- 1..48, do: Player.perform(id, fn -> :ok end)
      assert 2 = Player.get_ap(id)

      assert {:error, :exhausted} = Player.perform(id, 3, fn -> :ok end)
      assert 2 = Player.get_ap(id)
    end

    test "action fn is not called when exhausted", %{id: id} do
      for _ <- 1..50, do: Player.perform(id, fn -> :ok end)

      test_pid = self()

      assert {:error, :exhausted} =
               Player.perform(id, fn ->
                 send(test_pid, :action_ran)
               end)

      refute_received :action_ran
    end
  end
end
