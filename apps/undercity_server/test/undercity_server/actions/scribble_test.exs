defmodule UndercityServer.Actions.ScribbleTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Item
  alias UndercityServer.Actions.Scribble
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Test.Helpers

  setup do
    actor_id = Helpers.start_player!()
    block_id = Helpers.start_block!()
    Block.join(block_id, actor_id)
    %{actor_id: actor_id, block_id: block_id}
  end

  describe "scribble/3 — empty message" do
    test "returns ok noop and writes success inbox when text is blank", %{actor_id: actor_id, block_id: block_id} do
      initial_ap = Player.constitution(actor_id).ap

      assert {:ok, ^initial_ap} = Scribble.scribble(actor_id, block_id, "")
      :timer.sleep(10)

      assert [{:success, "You scribble on the ground."}] = Player.fetch_inbox(actor_id)
    end

    test "does not consume chalk when text is blank", %{actor_id: actor_id, block_id: block_id} do
      Player.add_item(actor_id, Item.new("Chalk", 3))

      Scribble.scribble(actor_id, block_id, "")

      assert [%Item{name: "Chalk", uses: 3}] = Player.check_inventory(actor_id)
    end
  end

  describe "scribble/3 — item missing" do
    test "returns ok noop and writes failure inbox when no chalk", %{actor_id: actor_id, block_id: block_id} do
      initial_ap = Player.constitution(actor_id).ap

      assert {:ok, ^initial_ap} = Scribble.scribble(actor_id, block_id, "hello")
      :timer.sleep(10)

      assert [{:failure, "You have no chalk."}] = Player.fetch_inbox(actor_id)
    end
  end

  describe "scribble/3 — success" do
    test "consumes chalk, spends AP, writes to block, and sends success inbox", %{
      actor_id: actor_id,
      block_id: block_id
    } do
      Player.add_item(actor_id, Item.new("Chalk", 3))

      assert {:ok, 49} = Scribble.scribble(actor_id, block_id, "hello")
      :timer.sleep(10)

      assert [%Item{name: "Chalk", uses: 2}] = Player.check_inventory(actor_id)
      assert 49 = Player.constitution(actor_id).ap
      assert {^block_id, _, "hello"} = Block.info(block_id)
      assert [{:success, "You scribble on the ground."}] = Player.fetch_inbox(actor_id)
    end
  end
end
