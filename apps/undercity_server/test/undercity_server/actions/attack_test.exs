defmodule UndercityServer.Actions.AttackTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityServer.Actions.Attack
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Test.Helpers

  setup do
    actor_id = Helpers.start_player!()
    block_id = Helpers.start_block!()
    Block.join(block_id, actor_id)
    %{actor_id: actor_id, block_id: block_id}
  end

  describe "attack/5 — invalid target" do
    test "returns ok noop and writes warning inbox when target not in block", %{
      actor_id: actor_id,
      block_id: block_id
    } do
      outsider_id = Helpers.start_player!()
      Player.add_item(actor_id, Item.new("Iron Pipe"))
      initial_ap = Player.constitution(actor_id).ap

      assert {:ok, ^initial_ap} = Attack.attack(actor_id, "Attacker", block_id, outsider_id, 0)
      :timer.sleep(10)

      assert [{:warning, "You miss."}] = Player.fetch_inbox(actor_id)
    end

    test "returns ok noop and writes warning inbox when target equals attacker", %{
      actor_id: actor_id,
      block_id: block_id
    } do
      Player.add_item(actor_id, Item.new("Iron Pipe"))
      initial_ap = Player.constitution(actor_id).ap

      assert {:ok, ^initial_ap} = Attack.attack(actor_id, "Attacker", block_id, actor_id, 0)
      :timer.sleep(10)

      assert [{:warning, "You miss."}] = Player.fetch_inbox(actor_id)
    end
  end

  describe "attack/5 — invalid weapon" do
    setup %{block_id: block_id} do
      target_id = Helpers.start_player!()
      Block.join(block_id, target_id)
      %{target_id: target_id}
    end

    test "returns ok noop and writes failure inbox when item is not a weapon", %{
      actor_id: actor_id,
      block_id: block_id,
      target_id: target_id
    } do
      Player.add_item(actor_id, Item.new("Junk"))
      initial_ap = Player.constitution(actor_id).ap

      assert {:ok, ^initial_ap} = Attack.attack(actor_id, "Attacker", block_id, target_id, 0)
      :timer.sleep(10)

      assert [{:failure, "You can't attack with that."}] = Player.fetch_inbox(actor_id)
    end

    test "returns ok noop and writes failure inbox when index out of range", %{
      actor_id: actor_id,
      block_id: block_id,
      target_id: target_id
    } do
      initial_ap = Player.constitution(actor_id).ap

      assert {:ok, ^initial_ap} = Attack.attack(actor_id, "Attacker", block_id, target_id, 0)
      :timer.sleep(10)

      assert [{:failure, "You can't attack with that."}] = Player.fetch_inbox(actor_id)
    end
  end
end
