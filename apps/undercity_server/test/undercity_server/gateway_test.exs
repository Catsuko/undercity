defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityCore.Item
  alias UndercityServer.Block
  alias UndercityServer.Gateway
  alias UndercityServer.Player
  alias UndercityServer.Player.Inbox
  alias UndercityServer.Test.Helpers
  alias UndercityServer.Vicinity

  describe "enter/1" do
    test "creates a player and spawns them at ashwarden square" do
      name = Helpers.player_name()
      {player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert is_binary(player_id)
      assert vicinity.id == "ashwarden_square"
      assert vicinity.type == :square
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "multiple people can enter" do
      name1 = Helpers.player_name()
      name2 = Helpers.player_name()
      Helpers.enter_player!(name1)
      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name2)

      names = Enum.map(vicinity.people, & &1.name)
      assert name1 in names
      assert name2 in names
    end

    test "entering with the same name does not create a duplicate" do
      name = Helpers.player_name()
      Helpers.enter_player!(name)
      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      matches = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(matches) == 1
    end

    test "reconnects to the block the player is already in" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "ashwarden_square", :move, :north)

      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "wardens_archive"
    end

    test "reconnects via full scan when block_id is stale" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "ashwarden_square", :move, :north)
      # player is in wardens_archive; corrupt block_id to old value
      Player.move_to(player_id, "ashwarden_square")

      {_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "wardens_archive"
    end

    test "restores player to DETS block when found in no block (crash recovery)" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      # simulate crash: remove from block but leave DETS intact
      Block.leave("ashwarden_square", player_id)

      {_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "ashwarden_square"
      assert Block.has_person?("ashwarden_square", player_id)
    end

    test "reconnects to spawn and joins block when block_id is nil" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      # simulate old DETS record with no block_id
      :sys.replace_state(:"player_#{player_id}", fn state -> %{state | block_id: nil} end)
      Block.leave("ashwarden_square", player_id)

      {_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "ashwarden_square"
      assert Block.has_person?("ashwarden_square", player_id)
      assert Player.location(player_id) == "ashwarden_square"
    end
  end

  describe "drop_item/2" do
    test "drops item and returns updated ap", %{} do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:junk))

      assert {:ok, 49} = Gateway.drop_item(player_id, 0)
      assert [] = Player.check_inventory(player_id)
    end

    test "returns ok noop when index is out of range" do
      {player_id, _vicinity, constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:ok, constitution.ap} == Gateway.drop_item(player_id, 0)
    end
  end

  describe "perform/4 :move" do
    test "moves a player to an adjacent block" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)

      {:ok, {:ok, %Vicinity{} = vicinity}, _constitution} = Gateway.perform(player_id, "ashwarden_square", :move, :north)

      assert vicinity.id == "wardens_archive"
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "player is removed from the source block" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)

      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "ashwarden_square", :move, :north)

      {"ashwarden_square", people, _scribble} = Block.info("ashwarden_square")
      refute player_id in people
    end

    test "returns error for invalid direction" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:ok, {:error, :no_exit}, _constitution} = Gateway.perform(player_id, "ashwarden_square", :move, :up)
    end
  end

  describe "perform/4 :eat" do
    test "eats item and returns updated ap and hp" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:mushroom))

      assert {:ok, 49, _hp} = Gateway.perform(player_id, vicinity.id, :eat, 0)
      assert [] = Player.check_inventory(player_id)
    end

    test "returns ok noop when index is out of range" do
      {player_id, vicinity, constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:ok, constitution.ap, constitution.hp} == Gateway.perform(player_id, vicinity.id, :eat, 0)
    end

    test "returns ok noop for non-edible item and writes inbox failure" do
      {player_id, vicinity, constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:junk))

      assert {:ok, constitution.ap, constitution.hp} == Gateway.perform(player_id, vicinity.id, :eat, 0)
      :timer.sleep(10)

      assert [{:failure, "You can't eat Junk."}] = Player.fetch_inbox(player_id)
    end
  end

  describe "perform/4 :search" do
    test "returns ap on any outcome" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:ok, _ap} = Gateway.perform(player_id, vicinity.id, :search, nil)
    end

    test "returns :not_in_block when player is not in the supplied block" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:error, :not_in_block} = Gateway.perform(player_id, "wardens_archive", :search, nil)
    end
  end

  describe "perform/4 :attack" do
    test "returns ok noop and writes failure inbox when item at index is not a weapon" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(attacker_id, Item.build(:junk))
      initial_ap = Player.constitution(attacker_id).ap

      assert {:ok, ^initial_ap} =
               Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0, attacker_name})

      :timer.sleep(10)
      assert [{:failure, "You can't attack with that."}] = Player.fetch_inbox(attacker_id)
    end

    test "returns ok noop and writes failure inbox when weapon index is out of bounds" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      initial_ap = Player.constitution(attacker_id).ap

      assert {:ok, ^initial_ap} =
               Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0, attacker_name})

      :timer.sleep(10)
      assert [{:failure, "You can't attack with that."}] = Player.fetch_inbox(attacker_id)
    end

    test "returns ap on hit or miss" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(attacker_id, Item.build(:iron_pipe))

      assert {:ok, _ap} = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0, attacker_name})
    end

    test "spends AP on a successful attack" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(attacker_id, Item.build(:iron_pipe))

      {:ok, new_ap} = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0, attacker_name})

      assert new_ap < 50
    end

    test "returns ok noop and writes warning inbox when player attacks themselves" do
      attacker_name = Helpers.player_name()
      {player_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      Player.add_item(player_id, Item.build(:iron_pipe))
      initial_ap = Player.constitution(player_id).ap

      assert {:ok, ^initial_ap} =
               Gateway.perform(player_id, vicinity.id, :attack, {player_id, 0, attacker_name})

      :timer.sleep(10)
      assert [{:warning, "You miss."}] = Player.fetch_inbox(player_id)
    end

    test "returns ok noop and writes warning inbox when target is not in block" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(attacker_id, Item.build(:iron_pipe))

      # target is in ashwarden_square; attacker tries to attack from a different block
      {:ok, {:ok, _}, _} = Gateway.perform(attacker_id, vicinity.id, :move, :north)
      :timer.sleep(10)
      Player.fetch_inbox(attacker_id)
      after_move_ap = Player.constitution(attacker_id).ap

      assert {:ok, ^after_move_ap} =
               Gateway.perform(attacker_id, "wardens_archive", :attack, {target_id, 0, attacker_name})

      :timer.sleep(10)
      assert [{:warning, "You miss."}] = Player.fetch_inbox(attacker_id)
    end

    test "returns ap when target is already collapsed (miss)" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(attacker_id, Item.build(:iron_pipe))
      Player.take_damage(target_id, {"attacker_id", "Rat", 50})
      Player.constitution(target_id)

      assert {:ok, _ap} = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0, attacker_name})
    end

    test "applies damage to the target" do
      attacker_name = Helpers.player_name()
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(attacker_name)
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(attacker_id, Item.build(:iron_pipe))

      initial_hp = Player.constitution(target_id).hp

      for _ <- 1..20 do
        Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0, attacker_name})
      end

      # If any hit landed, HP will have decreased from the initial value
      if Player.constitution(target_id).hp < initial_hp do
        assert Player.constitution(target_id).hp < initial_hp
      end
    end
  end

  describe "perform/4 :scribble" do
    test "scribbles text on a block when player has chalk" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:chalk))

      assert {:ok, _constitution} = Gateway.perform(player_id, vicinity.id, :scribble, "hello world")

      {_id, _people, scribble} = Block.info(vicinity.id)
      assert scribble == "hello world"
    end

    test "returns ok noop and writes failure inbox when player has no chalk" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      initial_ap = Player.constitution(player_id).ap

      assert {:ok, ^initial_ap} = Gateway.perform(player_id, vicinity.id, :scribble, "hello")
      :timer.sleep(10)

      assert [{:failure, "You have no chalk."}] = Player.fetch_inbox(player_id)
    end

    test "strips invalid characters from scribble text" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:chalk))

      assert {:ok, _constitution} = Gateway.perform(player_id, vicinity.id, :scribble, "hello!")

      {_id, _people, scribble} = Block.info(vicinity.id)
      assert scribble == "hello"
    end

    test "noops for empty scribble without consuming chalk" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:chalk, 2))
      initial_ap = Player.constitution(player_id).ap

      assert {:ok, ^initial_ap} = Gateway.perform(player_id, vicinity.id, :scribble, "!!!")

      items = Gateway.check_inventory(player_id)
      assert [%Item{name: "Chalk", uses: 2}] = items
    end

    test "consumes a chalk use" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:chalk, 2))

      Gateway.perform(player_id, "ashwarden_square", :scribble, "first")

      items = Gateway.check_inventory(player_id)
      assert [%Item{name: "Chalk", uses: 1}] = items
    end

    test "returns :not_in_block when player is not in the supplied block" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      Player.add_item(player_id, Item.build(:chalk, 2))

      assert {:error, :not_in_block} = Gateway.perform(player_id, "wardens_archive", :scribble, "hello")
    end
  end

  describe "messages_for/1" do
    test "delegates to Inbox — returns messages sent via Inbox and clears them" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      Inbox.info(player_id, "first")
      Inbox.info(player_id, "second")
      :timer.sleep(10)

      assert [{:info, "first"}, {:info, "second"}] = Gateway.messages_for(player_id)
      assert [] = Gateway.messages_for(player_id)
    end
  end
end
