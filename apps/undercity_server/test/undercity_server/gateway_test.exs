defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Gateway
  alias UndercityServer.Vicinity

  defp unique_name, do: "player_#{:rand.uniform(100_000)}"

  describe "enter/1" do
    test "creates a player and spawns them in the plaza" do
      name = unique_name()
      {player_id, %Vicinity{} = vicinity, _ap} = Gateway.enter(name)

      assert is_binary(player_id)
      assert vicinity.id == "plaza"
      assert vicinity.type == :square
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "multiple people can enter" do
      name1 = unique_name()
      name2 = unique_name()
      Gateway.enter(name1)
      {_player_id, %Vicinity{} = vicinity, _ap} = Gateway.enter(name2)

      names = Enum.map(vicinity.people, & &1.name)
      assert name1 in names
      assert name2 in names
    end

    test "entering with the same name does not create a duplicate" do
      name = unique_name()
      Gateway.enter(name)
      {_player_id, %Vicinity{} = vicinity, _ap} = Gateway.enter(name)

      matches = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(matches) == 1
    end

    test "reconnects to the block the player is already in" do
      name = unique_name()
      {player_id, _vicinity, _ap} = Gateway.enter(name)
      {:ok, {:ok, _vicinity}, _ap} = Gateway.move(player_id, :north, "plaza")

      {_player_id, %Vicinity{} = vicinity, _ap} = Gateway.enter(name)

      assert vicinity.id == "north_alley"
    end
  end

  describe "move/3" do
    test "moves a player to an adjacent block" do
      name = unique_name()
      {player_id, _vicinity, _ap} = Gateway.enter(name)

      {:ok, {:ok, %Vicinity{} = vicinity}, _ap} = Gateway.move(player_id, :north, "plaza")

      assert vicinity.id == "north_alley"
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "player is removed from the source block" do
      name = unique_name()
      {player_id, _vicinity, _ap} = Gateway.enter(name)

      {:ok, {:ok, _vicinity}, _ap} = Gateway.move(player_id, :north, "plaza")

      {"plaza", people} = UndercityServer.Block.info("plaza")
      refute player_id in people
    end

    test "returns error for invalid direction" do
      {player_id, _vicinity, _ap} = Gateway.enter(unique_name())

      assert {:ok, {:error, :no_exit}, _ap} = Gateway.move(player_id, :up, "plaza")
    end
  end

  describe "search/2" do
    test "returns :nothing or {:found, item} wrapped in perform tuple" do
      {player_id, vicinity, _ap} = Gateway.enter(unique_name())

      {:ok, result, _ap} = Gateway.search(player_id, vicinity.id)

      assert result == :nothing or match?({:found, _item}, result)
    end
  end

  describe "scribble/3" do
    test "scribbles text on a block when player has chalk" do
      {player_id, vicinity, _ap} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 5))
      Process.sleep(10)

      assert {:ok, :ok, _ap} = Gateway.scribble(player_id, vicinity.id, "hello world")

      assert "hello world" = UndercityServer.Block.get_scribble(vicinity.id)
    end

    test "returns error when player has no chalk" do
      {player_id, vicinity, _ap} = Gateway.enter(unique_name())

      assert {:ok, {:error, :no_chalk}, _ap} = Gateway.scribble(player_id, vicinity.id, "hello")
    end

    test "strips invalid characters from scribble text" do
      {player_id, vicinity, _ap} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 5))
      Process.sleep(10)

      assert {:ok, :ok, _ap} = Gateway.scribble(player_id, vicinity.id, "hello!")

      assert "hello" = UndercityServer.Block.get_scribble(vicinity.id)
    end

    test "noops for empty scribble without consuming chalk" do
      {player_id, vicinity, _ap} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))
      Process.sleep(10)

      assert {:ok, :ok, _ap} = Gateway.scribble(player_id, vicinity.id, "!!!")

      items = Gateway.get_inventory(player_id)
      assert [%UndercityCore.Item{name: "Chalk", uses: 2}] = items
    end

    test "consumes a chalk use" do
      {player_id, _vicinity, _ap} = Gateway.enter(unique_name())
      UndercityServer.Player.add_item(player_id, UndercityCore.Item.new("Chalk", 2))
      Process.sleep(10)

      Gateway.scribble(player_id, "plaza", "first")

      items = Gateway.get_inventory(player_id)
      assert [%UndercityCore.Item{name: "Chalk", uses: 1}] = items
    end
  end
end
