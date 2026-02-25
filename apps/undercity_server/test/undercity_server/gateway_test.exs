defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Block
  alias UndercityServer.Gateway
  alias UndercityServer.Test.Helpers
  alias UndercityServer.Vicinity

  describe "enter/1" do
    test "creates a player and spawns them in the plaza" do
      name = Helpers.player_name()
      {player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert is_binary(player_id)
      assert vicinity.id == "plaza"
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
      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)

      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "north_alley"
    end

    test "reconnects via full scan when block_id is stale" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)
      # player is in north_alley; corrupt block_id to old value
      :sys.replace_state(:"player_#{player_id}", fn state -> %{state | block_id: "plaza"} end)

      {_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "north_alley"
    end

    test "restores player to DETS block when found in no block (crash recovery)" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      # simulate crash: remove from block but leave DETS intact
      Block.leave("plaza", player_id)

      {_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "plaza"
      assert Block.has_person?("plaza", player_id)
    end

    test "reconnects to spawn and joins block when block_id is nil" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)
      # simulate old DETS record with no block_id
      :sys.replace_state(:"player_#{player_id}", fn state -> %{state | block_id: nil} end)
      Block.leave("plaza", player_id)

      {_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert vicinity.id == "plaza"
      assert Block.has_person?("plaza", player_id)
      assert UndercityServer.Player.location(player_id) == "plaza"
    end
  end

  describe "perform/4 :move" do
    test "moves a player to an adjacent block" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)

      {:ok, {:ok, %Vicinity{} = vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)

      assert vicinity.id == "north_alley"
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "player is removed from the source block" do
      name = Helpers.player_name()
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(name)

      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)

      {"plaza", people} = Block.info("plaza")
      refute player_id in people
    end

    test "returns error for invalid direction" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:ok, {:error, :no_exit}, _constitution} = Gateway.perform(player_id, "plaza", :move, :up)
    end
  end

  describe "perform/4 :search" do
    test "returns :nothing or {:found, item} wrapped in perform tuple" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      {:ok, result, _constitution} = Gateway.perform(player_id, vicinity.id, :search, nil)

      assert result == :nothing or match?({:found, _item}, result)
    end

    test "returns :not_in_block when player is not in the supplied block" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:error, :not_in_block} = Gateway.perform(player_id, "north_alley", :search, nil)
    end
  end

  describe "perform/4 :attack" do
    test "returns :invalid_weapon when item at index is not a weapon" do
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(attacker_id, UndercityCore.Item.new("Junk"))

      assert {:error, :invalid_weapon} = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0})
    end

    test "returns :invalid_weapon when weapon index is out of bounds" do
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:error, :invalid_weapon} = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0})
    end

    test "returns hit or miss result with an iron pipe" do
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(attacker_id, UndercityCore.Item.new("Iron Pipe"))

      result = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0})

      assert match?({:ok, {:hit, _, "Iron Pipe", _}, _}, result) or
               match?({:ok, {:miss, _}, _}, result) or
               match?({:ok, {:collapsed, _, "Iron Pipe", _}, _}, result)
    end

    test "spends AP on a successful attack" do
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(attacker_id, UndercityCore.Item.new("Iron Pipe"))

      {:ok, _outcome, new_ap} = Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0})

      assert new_ap < 50
    end

    test "returns :invalid_target when player attacks themselves" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Iron Pipe"))

      assert {:error, :invalid_target} = Gateway.perform(player_id, vicinity.id, :attack, {player_id, 0})
    end

    test "returns :invalid_target when target is not in block" do
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(attacker_id, UndercityCore.Item.new("Iron Pipe"))

      # target is in plaza; attacker tries to attack from a different block
      {:ok, {:ok, _}, _} = Gateway.perform(attacker_id, vicinity.id, :move, :north)

      assert {:error, :invalid_target} =
               Gateway.perform(attacker_id, "north_alley", :attack, {target_id, 0})
    end

    test "applies damage to the target" do
      {attacker_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      {target_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(attacker_id, UndercityCore.Item.new("Iron Pipe"))

      initial_hp = UndercityServer.Player.constitution(target_id).hp

      # Run attacks until one lands to verify damage is applied
      result =
        Enum.find_value(1..20, fn _ ->
          case Gateway.perform(attacker_id, vicinity.id, :attack, {target_id, 0}) do
            {:ok, {:hit, _, _, _}, _} = r -> r
            {:ok, {:collapsed, _, _, _}, _} = r -> r
            _ -> nil
          end
        end)

      if result do
        assert UndercityServer.Player.constitution(target_id).hp < initial_hp
      end
    end
  end

  describe "perform/4 :scribble" do
    test "scribbles text on a block when player has chalk" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 5))

      assert {:ok, _constitution} = Gateway.perform(player_id, vicinity.id, :scribble, "hello world")

      assert "hello world" = Block.get_scribble(vicinity.id)
    end

    test "returns error when player has no chalk" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert {:error, :item_missing} = Gateway.perform(player_id, vicinity.id, :scribble, "hello")
    end

    test "strips invalid characters from scribble text" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 5))

      assert {:ok, _constitution} = Gateway.perform(player_id, vicinity.id, :scribble, "hello!")

      assert "hello" = Block.get_scribble(vicinity.id)
    end

    test "noops for empty scribble without consuming chalk" do
      {player_id, vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))

      assert {:error, :empty_message} = Gateway.perform(player_id, vicinity.id, :scribble, "!!!")

      items = Gateway.check_inventory(player_id)
      assert [%UndercityCore.Item{name: "Chalk", uses: 2}] = items
    end

    test "consumes a chalk use" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))

      Gateway.perform(player_id, "plaza", :scribble, "first")

      items = Gateway.check_inventory(player_id)
      assert [%UndercityCore.Item{name: "Chalk", uses: 1}] = items
    end

    test "returns :not_in_block when player is not in the supplied block" do
      {player_id, _vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))

      assert {:error, :not_in_block} = Gateway.perform(player_id, "north_alley", :scribble, "hello")
    end
  end
end
