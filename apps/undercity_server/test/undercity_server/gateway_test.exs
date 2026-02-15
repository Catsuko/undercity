defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Gateway
  alias UndercityServer.Vicinity

  defp unique_name, do: "player_#{:rand.uniform(100_000)}"

  describe "enter/1" do
    test "creates a player and spawns them in the plaza" do
      name = unique_name()
      {player_id, %Vicinity{} = vicinity, _constitution} = Gateway.enter(name)

      assert is_binary(player_id)
      assert vicinity.id == "plaza"
      assert vicinity.type == :square
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "multiple people can enter" do
      name1 = unique_name()
      name2 = unique_name()
      Gateway.enter(name1)
      {_player_id, %Vicinity{} = vicinity, _constitution} = Gateway.enter(name2)

      names = Enum.map(vicinity.people, & &1.name)
      assert name1 in names
      assert name2 in names
    end

    test "entering with the same name does not create a duplicate" do
      name = unique_name()
      Gateway.enter(name)
      {_player_id, %Vicinity{} = vicinity, _constitution} = Gateway.enter(name)

      matches = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(matches) == 1
    end

    test "reconnects to the block the player is already in" do
      name = unique_name()
      {player_id, _vicinity, _constitution} = Gateway.enter(name)
      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)

      {_player_id, %Vicinity{} = vicinity, _constitution} = Gateway.enter(name)

      assert vicinity.id == "north_alley"
    end
  end

  describe "perform/4 :move" do
    test "moves a player to an adjacent block" do
      name = unique_name()
      {player_id, _vicinity, _constitution} = Gateway.enter(name)

      {:ok, {:ok, %Vicinity{} = vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)

      assert vicinity.id == "north_alley"
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "player is removed from the source block" do
      name = unique_name()
      {player_id, _vicinity, _constitution} = Gateway.enter(name)

      {:ok, {:ok, _vicinity}, _constitution} = Gateway.perform(player_id, "plaza", :move, :north)

      {"plaza", people} = UndercityServer.Block.info("plaza")
      refute player_id in people
    end

    test "returns error for invalid direction" do
      {player_id, _vicinity, _constitution} = Gateway.enter(unique_name())

      assert {:ok, {:error, :no_exit}, _constitution} = Gateway.perform(player_id, "plaza", :move, :up)
    end
  end

  describe "perform/4 :search" do
    test "returns :nothing or {:found, item} wrapped in perform tuple" do
      {player_id, vicinity, _constitution} = Gateway.enter(unique_name())

      {:ok, result, _constitution} = Gateway.perform(player_id, vicinity.id, :search, nil)

      assert result == :nothing or match?({:found, _item}, result)
    end
  end

  describe "perform/4 :scribble" do
    test "scribbles text on a block when player has chalk" do
      {player_id, vicinity, _constitution} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 5))

      assert {:ok, _constitution} = Gateway.perform(player_id, vicinity.id, :scribble, "hello world")

      assert "hello world" = UndercityServer.Block.get_scribble(vicinity.id)
    end

    test "returns error when player has no chalk" do
      {player_id, vicinity, _constitution} = Gateway.enter(unique_name())

      assert {:error, :item_missing} = Gateway.perform(player_id, vicinity.id, :scribble, "hello")
    end

    test "strips invalid characters from scribble text" do
      {player_id, vicinity, _constitution} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 5))

      assert {:ok, _constitution} = Gateway.perform(player_id, vicinity.id, :scribble, "hello!")

      assert "hello" = UndercityServer.Block.get_scribble(vicinity.id)
    end

    test "noops for empty scribble without consuming chalk" do
      {player_id, vicinity, _constitution} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))

      assert {:error, :empty_message} = Gateway.perform(player_id, vicinity.id, :scribble, "!!!")

      items = Gateway.check_inventory(player_id)
      assert [%UndercityCore.Item{name: "Chalk", uses: 2}] = items
    end

    test "consumes a chalk use" do
      {player_id, _vicinity, _constitution} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))

      Gateway.perform(player_id, "plaza", :scribble, "first")

      items = Gateway.check_inventory(player_id)
      assert [%UndercityCore.Item{name: "Chalk", uses: 1}] = items
    end
  end
end
