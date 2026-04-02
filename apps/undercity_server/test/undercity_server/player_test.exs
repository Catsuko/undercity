defmodule UndercityServer.PlayerTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Health
  alias UndercityCore.Item
  alias UndercityServer.Player
  alias UndercityServer.Test.Helpers

  setup do
    id = Helpers.start_player!()
    %{id: id}
  end

  defp collapse(id) do
    :sys.replace_state(:"player_#{id}", fn state ->
      %{state | player: %{state.player | health: %Health{hp: 0}}}
    end)
  end

  describe "use_item/2" do
    test "decrements uses on a consumable item", %{id: id} do
      Player.add_item(id, Item.build(:chalk))

      assert :ok = Player.use_item(id, "Chalk")

      items = Player.check_inventory(id)
      assert [%Item{name: "Chalk", uses: 4}] = items
    end

    test "removes item when last use is spent", %{id: id} do
      Player.add_item(id, Item.build(:chalk, 1))

      assert :ok = Player.use_item(id, "Chalk")

      assert [] = Player.check_inventory(id)
    end

    test "returns :not_found when item is not in inventory", %{id: id} do
      assert :not_found = Player.use_item(id, "Chalk")
    end

    test "non-consumable items are not removed", %{id: id} do
      Player.add_item(id, Item.build(:junk))

      assert :ok = Player.use_item(id, "Junk")

      items = Player.check_inventory(id)
      assert [%Item{name: "Junk"}] = items
    end
  end

  describe "use_item/3 (atomic AP + item)" do
    test "spends AP and consumes item atomically", %{id: id} do
      Player.add_item(id, Item.build(:chalk))

      assert {:ok, 49} = Player.use_item(id, 0, 1)

      assert [%Item{name: "Chalk", uses: 4}] = Player.check_inventory(id)
      assert 49 = Player.constitution(id).ap
    end

    test "removes item on last use", %{id: id} do
      Player.add_item(id, Item.build(:chalk, 1))

      assert {:ok, 49} = Player.use_item(id, 0, 1)

      assert [] = Player.check_inventory(id)
    end

    test "returns :exhausted when AP insufficient, item untouched", %{id: id} do
      Player.add_item(id, Item.build(:chalk))

      # Drain all AP
      for _ <- 1..50, do: Player.perform(id, fn -> :ok end)

      assert {:error, :exhausted} = Player.use_item(id, 0, 1)

      assert [%Item{name: "Chalk", uses: 5}] = Player.check_inventory(id)
    end

    test "returns :item_missing when item not in inventory, AP untouched", %{id: id} do
      assert {:error, :item_missing} = Player.use_item(id, 0, 1)

      assert 50 = Player.constitution(id).ap
    end

    test "spends custom AP cost", %{id: id} do
      Player.add_item(id, Item.build(:chalk))

      assert {:ok, 47} = Player.use_item(id, 0, 3)

      assert 47 = Player.constitution(id).ap
    end
  end

  describe "drop_item/2" do
    test "removes item at index and spends AP", %{id: id} do
      Player.add_item(id, Item.build(:junk))
      Player.add_item(id, Item.build(:chalk))

      assert {:ok, 49} = Player.drop_item(id, 0)

      assert [%Item{name: "Chalk", uses: 5}] = Player.check_inventory(id)
    end

    test "returns ok noop for out of range index", %{id: id} do
      initial_ap = Player.constitution(id).ap
      assert {:ok, ^initial_ap} = Player.drop_item(id, 0)
      assert [] = Player.fetch_inbox(id)
    end

    test "returns :exhausted when AP insufficient and writes inbox warning", %{id: id} do
      Player.add_item(id, Item.build(:junk))

      for _ <- 1..50, do: Player.perform(id, fn -> :ok end)

      assert {:error, :exhausted} = Player.drop_item(id, 0)
      :timer.sleep(10)

      assert [%Item{name: "Junk"}] = Player.check_inventory(id)
      assert [{:warning, "You are too exhausted to act."}] = Player.fetch_inbox(id)
    end

    test "returns :collapsed when HP is zero and writes inbox warning", %{id: id} do
      Player.add_item(id, Item.build(:junk))
      collapse(id)

      assert {:error, :collapsed} = Player.drop_item(id, 0)
      :timer.sleep(10)

      assert [%Item{name: "Junk"}] = Player.check_inventory(id)
      assert [{:warning, "Your body has given out."}] = Player.fetch_inbox(id)
    end
  end

  describe "eat_item/2" do
    test "consumes edible item and returns ap and hp", %{id: id} do
      Player.add_item(id, Item.build(:mushroom))

      assert {:ok, 49, _hp} = Player.eat_item(id, 0)

      assert [] = Player.check_inventory(id)
    end

    test "applies food effect to health", %{id: _id} do
      # Run many eat attempts across fresh players to observe both heal and damage effects
      # Pre-damage each player so there is room for healing to register as a positive delta
      results =
        for _ <- 1..100 do
          fresh_id = Helpers.start_player!()
          Player.take_damage(fresh_id, {"attacker_id", "Rat", 10})
          Player.add_item(fresh_id, Item.build(:mushroom))
          initial_hp = Player.constitution(fresh_id).hp
          {:ok, _ap, new_hp} = Player.eat_item(fresh_id, 0)
          new_hp - initial_hp
        end

      # Verify at least one heal (+5) and one damage (-5) occurred
      assert Enum.any?(results, fn delta -> delta > 0 end)
      assert Enum.any?(results, fn delta -> delta < 0 end)
    end

    test "returns ok noop for non-edible item", %{id: id} do
      Player.add_item(id, Item.build(:junk))
      initial = Player.constitution(id)

      assert {:ok, initial.ap, initial.hp} == Player.eat_item(id, 0)
      assert [%Item{name: "Junk"}] = Player.check_inventory(id)
    end

    test "returns ok noop for out of range index", %{id: id} do
      initial = Player.constitution(id)
      assert {:ok, initial.ap, initial.hp} == Player.eat_item(id, 0)
      assert [] = Player.fetch_inbox(id)
    end

    test "returns ok noop for non-edible item and writes inbox failure", %{id: id} do
      Player.add_item(id, Item.build(:junk))
      initial = Player.constitution(id)

      assert {:ok, initial.ap, initial.hp} == Player.eat_item(id, 0)
      :timer.sleep(10)

      assert [%Item{name: "Junk"}] = Player.check_inventory(id)
      assert [{:failure, "You can't eat Junk."}] = Player.fetch_inbox(id)
    end

    test "returns :exhausted when AP insufficient and writes inbox warning", %{id: id} do
      Player.add_item(id, Item.build(:mushroom))

      for _ <- 1..50, do: Player.perform(id, fn -> :ok end)

      assert {:error, :exhausted} = Player.eat_item(id, 0)
      :timer.sleep(10)

      assert [%Item{name: "Mushroom"}] = Player.check_inventory(id)
      assert [{:warning, "You are too exhausted to act."}] = Player.fetch_inbox(id)
    end

    test "returns :collapsed when HP is zero and writes inbox warning", %{id: id} do
      Player.add_item(id, Item.build(:mushroom))
      collapse(id)

      assert {:error, :collapsed} = Player.eat_item(id, 0)
      :timer.sleep(10)

      assert [%Item{name: "Mushroom"}] = Player.check_inventory(id)
      assert [{:warning, "Your body has given out."}] = Player.fetch_inbox(id)
    end

    test "does not consume item when not edible", %{id: id} do
      Player.add_item(id, Item.build(:chalk))

      assert {:ok, _ap, _hp} = Player.eat_item(id, 0)
      assert [%Item{name: "Chalk", uses: 5}] = Player.check_inventory(id)
    end

    test "does not spend AP when item is not edible", %{id: id} do
      Player.add_item(id, Item.build(:junk))

      assert {:ok, 50, _hp} = Player.eat_item(id, 0)
      assert 50 = Player.constitution(id).ap
    end
  end

  describe "add_item/2" do
    test "returns error when inventory is full", %{id: id} do
      for _ <- 1..15, do: Player.add_item(id, Item.build(:junk))

      assert {:error, :full} = Player.add_item(id, Item.build(:junk))
    end
  end

  describe "constitution/1" do
    test "new player starts with 50 AP", %{id: id} do
      assert 50 = Player.constitution(id).ap
    end

    test "new player starts with 50 HP", %{id: id} do
      assert 50 = Player.constitution(id).hp
    end
  end

  describe "collapsed (0 HP) blocks actions" do
    test "perform returns :collapsed", %{id: id} do
      collapse(id)
      assert {:error, :collapsed} = Player.perform(id, fn -> :should_not_run end)
    end

    test "drop_item returns :collapsed", %{id: id} do
      Player.add_item(id, Item.build(:junk))
      collapse(id)

      assert {:error, :collapsed} = Player.drop_item(id, 0)
      assert [%Item{name: "Junk"}] = Player.check_inventory(id)
    end

    test "eat_item returns :collapsed", %{id: id} do
      Player.add_item(id, Item.build(:mushroom))
      collapse(id)

      assert {:error, :collapsed} = Player.eat_item(id, 0)
      assert [%Item{name: "Mushroom"}] = Player.check_inventory(id)
    end

    test "use_item/3 returns :collapsed", %{id: id} do
      Player.add_item(id, Item.build(:chalk))
      collapse(id)

      assert {:error, :collapsed} = Player.use_item(id, 0, 1)
      assert [%Item{name: "Chalk", uses: 5}] = Player.check_inventory(id)
    end

    test "action fn is not called when collapsed", %{id: id} do
      collapse(id)
      test_pid = self()

      assert {:error, :collapsed} =
               Player.perform(id, fn ->
                 send(test_pid, :action_ran)
               end)

      refute_received :action_ran
    end
  end

  describe "take_damage/2" do
    test "reduces HP by the given amount", %{id: id} do
      Player.take_damage(id, {"attacker_id", "Rat", 5})
      assert 45 = Player.constitution(id).hp
    end

    test "clamps HP at 0 when damage exceeds current HP", %{id: id} do
      Player.take_damage(id, {"attacker_id", "Rat", 100})
      assert 0 = Player.constitution(id).hp
    end

    test "silently drops when player is already at 0 HP", %{id: id} do
      Player.take_damage(id, {"attacker_id", "Rat", 50})
      Player.take_damage(id, {"attacker_id", "Rat", 10})
      assert 0 = Player.constitution(id).hp
    end

    test "sends warning inbox message to target", %{id: id} do
      Player.take_damage(id, {"attacker_id", "Rat", 5})
      :timer.sleep(10)

      assert [{:warning, "Rat hits you for 5 damage."}] = Player.fetch_inbox(id)
    end

    test "sends success inbox message to attacker", %{id: id} do
      attacker_id = Helpers.start_player!()
      Player.take_damage(id, {attacker_id, "Rat", 5})
      :timer.sleep(10)

      assert [{:success, "You hit Test Player for 5 damage."}] = Player.fetch_inbox(attacker_id)
    end

    test "no inbox message when player is already collapsed", %{id: id} do
      collapse(id)
      Player.take_damage(id, {"attacker_id", "Rat", 5})
      :timer.sleep(10)

      assert [] = Player.fetch_inbox(id)
    end
  end

  describe "heal/4" do
    test "restores HP by the given amount", %{id: id} do
      Player.take_damage(id, {"attacker_id", "Rat", 20})
      assert :ok = Player.heal(id, 5, "healer_id", "Healer")
      assert 35 = Player.constitution(id).hp
    end

    test "clamps HP at max when heal exceeds deficit", %{id: id} do
      Player.take_damage(id, {"attacker_id", "Rat", 5})
      assert :ok = Player.heal(id, 100, "healer_id", "Healer")
      assert 50 = Player.constitution(id).hp
    end

    test "returns healed 0 when HP is at max", %{id: id} do
      assert :ok = Player.heal(id, 10, "healer_id", "Healer")
      assert 50 = Player.constitution(id).hp
    end

    test "returns :invalid_target when HP is 0", %{id: id} do
      collapse(id)
      assert {:error, :invalid_target} = Player.heal(id, 10, "healer_id", "Healer")
      assert 0 = Player.constitution(id).hp
    end
  end

  describe "block tracking" do
    test "location returns nil for a new player", %{id: id} do
      assert nil == Player.location(id)
    end

    test "move_to persists the block_id", %{id: id} do
      assert :ok = Player.move_to(id, "some_block")
      assert "some_block" == Player.location(id)
    end

    test "move_to can be updated to a new block", %{id: id} do
      Player.move_to(id, "block_a")
      Player.move_to(id, "block_b")
      assert "block_b" == Player.location(id)
    end
  end

  describe "spend_ap via perform/3" do
    test "spends AP and runs action", %{id: id} do
      assert {:ok, :acted, 49} = Player.perform(id, fn -> :acted end)
      assert 49 = Player.constitution(id).ap
    end

    test "spends custom cost", %{id: id} do
      assert {:ok, :ok, 45} = Player.perform(id, 5, fn -> :ok end)
      assert 45 = Player.constitution(id).ap
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
      assert 47 = Player.constitution(id).ap
    end

    test "spending exactly remaining AP succeeds", %{id: id} do
      # Drain to 3 AP
      for _ <- 1..47, do: Player.perform(id, fn -> :ok end)
      assert 3 = Player.constitution(id).ap

      assert {:ok, :ok, 0} = Player.perform(id, 3, fn -> :ok end)
      assert 0 = Player.constitution(id).ap
    end

    test "spending one more than remaining AP fails", %{id: id} do
      for _ <- 1..48, do: Player.perform(id, fn -> :ok end)
      assert 2 = Player.constitution(id).ap

      assert {:error, :exhausted} = Player.perform(id, 3, fn -> :ok end)
      assert 2 = Player.constitution(id).ap
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
