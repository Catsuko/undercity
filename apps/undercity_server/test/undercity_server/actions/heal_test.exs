defmodule UndercityServer.Actions.HealTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityServer.Actions.Heal
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Test.Helpers

  setup do
    actor_id = Helpers.start_player!()
    block_id = Helpers.start_block!()
    %{actor_id: actor_id, block_id: block_id}
  end

  defp damage(id, amount), do: Player.take_damage(id, {"attacker_id", "Rat", amount})

  describe "heal/6 — self-heal" do
    setup %{block_id: block_id, actor_id: actor_id} do
      Block.join(block_id, actor_id)
      :ok
    end

    test "consumes salve, restores HP, spends AP, and returns ap", %{actor_id: actor_id, block_id: block_id} do
      damage(actor_id, 20)
      Player.add_item(actor_id, Item.new("Salve", 1))

      assert {:ok, 49} = Heal.heal(actor_id, "player", block_id, actor_id, 0)

      assert [] = Player.check_inventory(actor_id)
      assert 49 = Player.constitution(actor_id).ap
      assert 45 = Player.constitution(actor_id).hp
    end

    test "heals 0 and consumes item when HP is at max", %{actor_id: actor_id, block_id: block_id} do
      Player.add_item(actor_id, Item.new("Salve", 1))

      assert {:ok, 49} = Heal.heal(actor_id, "player", block_id, actor_id, 0)

      assert [] = Player.check_inventory(actor_id)
      assert 49 = Player.constitution(actor_id).ap
    end

    test "returns :collapsed when actor HP is 0, item and AP untouched",
         %{actor_id: actor_id, block_id: block_id} do
      Player.add_item(actor_id, Item.new("Salve", 1))
      damage(actor_id, 50)

      assert {:error, :collapsed} = Heal.heal(actor_id, "player", block_id, actor_id, 0)

      assert [%Item{name: "Salve"}] = Player.check_inventory(actor_id)
    end

    test "returns :item_missing", %{actor_id: actor_id, block_id: block_id} do
      damage(actor_id, 20)

      assert {:error, :item_missing} = Heal.heal(actor_id, "player", block_id, actor_id, 0)
    end

    test "returns :not_a_remedy", %{actor_id: actor_id, block_id: block_id} do
      damage(actor_id, 20)
      Player.add_item(actor_id, Item.new("Junk"))

      assert {:error, :not_a_remedy} = Heal.heal(actor_id, "player", block_id, actor_id, 0)
    end

    test "sends inbox message to actor on self-heal", %{actor_id: actor_id, block_id: block_id} do
      damage(actor_id, 20)
      Player.add_item(actor_id, Item.new("Salve", 1))
      :timer.sleep(10)
      Player.fetch_inbox(actor_id)

      Heal.heal(actor_id, "player", block_id, actor_id, 0)
      :timer.sleep(10)

      assert [{:success, "You healed yourself for 15."}] = Player.fetch_inbox(actor_id)
    end

    test "sends inbox message to actor even when healed amount is 0", %{actor_id: actor_id, block_id: block_id} do
      Player.add_item(actor_id, Item.new("Salve", 1))
      :timer.sleep(10)
      Player.fetch_inbox(actor_id)

      Heal.heal(actor_id, "player", block_id, actor_id, 0)
      :timer.sleep(10)

      assert [{:success, "You healed yourself for 0."}] = Player.fetch_inbox(actor_id)
    end
  end

  describe "heal/6 — other-heal" do
    setup %{block_id: block_id, actor_id: actor_id} do
      target_id = Helpers.start_player!()
      Block.join(block_id, actor_id)
      Block.join(block_id, target_id)
      %{target_id: target_id}
    end

    test "consumes salve and restores target HP", %{actor_id: actor_id, block_id: block_id, target_id: target_id} do
      damage(target_id, 20)
      Player.add_item(actor_id, Item.new("Salve", 1))

      assert {:ok, 49} = Heal.heal(actor_id, "Healer", block_id, target_id, 0)

      assert [] = Player.check_inventory(actor_id)
      assert 49 = Player.constitution(actor_id).ap
      assert 45 = Player.constitution(target_id).hp
    end

    test "heals 0 and consumes item when target HP is at max", %{
      actor_id: actor_id,
      block_id: block_id,
      target_id: target_id
    } do
      Player.add_item(actor_id, Item.new("Salve", 1))

      assert {:ok, 49} = Heal.heal(actor_id, "Healer", block_id, target_id, 0)

      assert [] = Player.check_inventory(actor_id)
      assert 49 = Player.constitution(actor_id).ap
    end

    test "returns :invalid_target when target HP is 0", %{actor_id: actor_id, block_id: block_id, target_id: target_id} do
      damage(target_id, 50)
      Player.add_item(actor_id, Item.new("Salve", 1))

      assert {:error, :invalid_target} = Heal.heal(actor_id, "Healer", block_id, target_id, 0)

      assert [] = Player.check_inventory(actor_id)
      assert 49 = Player.constitution(actor_id).ap
    end

    test "returns :item_missing when actor has no salve", %{actor_id: actor_id, block_id: block_id, target_id: target_id} do
      damage(target_id, 20)

      assert {:error, :item_missing} = Heal.heal(actor_id, "Healer", block_id, target_id, 0)
    end

    test "returns :not_a_remedy", %{actor_id: actor_id, block_id: block_id, target_id: target_id} do
      damage(target_id, 20)
      Player.add_item(actor_id, Item.new("Junk"))

      assert {:error, :not_a_remedy} = Heal.heal(actor_id, "Healer", block_id, target_id, 0)
    end

    test "returns :invalid_target when target is not in block", %{actor_id: actor_id, block_id: block_id} do
      outsider_id = Helpers.start_player!()
      Player.add_item(actor_id, Item.new("Salve", 1))

      assert {:error, :invalid_target} = Heal.heal(actor_id, "Healer", block_id, outsider_id, 0)

      assert [%Item{name: "Salve"}] = Player.check_inventory(actor_id)
    end

    test "sends inbox message to target on success", %{actor_id: actor_id, block_id: block_id, target_id: target_id} do
      damage(target_id, 20)
      Player.add_item(actor_id, Item.new("Salve", 1))
      :timer.sleep(10)
      Player.fetch_inbox(target_id)

      Heal.heal(actor_id, "Healer", block_id, target_id, 0)
      :timer.sleep(10)

      assert [{:success, "Healer healed you for 15."}] = Player.fetch_inbox(target_id)
    end

    test "does not send inbox message to target when healed amount is 0", %{
      actor_id: actor_id,
      block_id: block_id,
      target_id: target_id
    } do
      Player.add_item(actor_id, Item.new("Salve", 1))
      :timer.sleep(10)
      Player.fetch_inbox(target_id)

      Heal.heal(actor_id, "Healer", block_id, target_id, 0)
      :timer.sleep(10)

      assert [] = Player.fetch_inbox(target_id)
    end

    test "sends inbox message to actor on other-heal", %{actor_id: actor_id, block_id: block_id, target_id: target_id} do
      damage(target_id, 20)
      Player.add_item(actor_id, Item.new("Salve", 1))
      :timer.sleep(10)
      Player.fetch_inbox(actor_id)

      Heal.heal(actor_id, "Healer", block_id, target_id, 0)
      :timer.sleep(10)

      assert [{:success, "You healed Test Player for 15."}] = Player.fetch_inbox(actor_id)
    end
  end
end
