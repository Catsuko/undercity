defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Gateway
  alias UndercityServer.Vicinity

  defp unique_name, do: "player_#{:rand.uniform(100_000)}"

  describe "enter/1" do
    test "creates a player and spawns them in the plaza" do
      name = unique_name()
      {player_id, %Vicinity{} = vicinity} = Gateway.enter(name)

      assert is_binary(player_id)
      assert vicinity.id == "plaza"
      assert vicinity.type == :square
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "multiple people can enter" do
      name1 = unique_name()
      name2 = unique_name()
      Gateway.enter(name1)
      {_player_id, %Vicinity{} = vicinity} = Gateway.enter(name2)

      names = Enum.map(vicinity.people, & &1.name)
      assert name1 in names
      assert name2 in names
    end

    test "entering with the same name does not create a duplicate" do
      name = unique_name()
      Gateway.enter(name)
      {_player_id, %Vicinity{} = vicinity} = Gateway.enter(name)

      matches = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(matches) == 1
    end

    test "reconnects to the block the player is already in" do
      name = unique_name()
      {player_id, _vicinity} = Gateway.enter(name)
      {:ok, _} = Gateway.move(player_id, :north, "plaza")

      {_player_id, %Vicinity{} = vicinity} = Gateway.enter(name)

      assert vicinity.id == "north_alley"
    end
  end

  describe "move/3" do
    test "moves a player to an adjacent block" do
      name = unique_name()
      {player_id, _vicinity} = Gateway.enter(name)

      {:ok, %Vicinity{} = vicinity} = Gateway.move(player_id, :north, "plaza")

      assert vicinity.id == "north_alley"
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "player is removed from the source block" do
      name = unique_name()
      {player_id, _vicinity} = Gateway.enter(name)

      {:ok, _} = Gateway.move(player_id, :north, "plaza")

      {"plaza", people} = UndercityServer.Block.info("plaza")
      refute player_id in people
    end

    test "returns error for invalid direction" do
      {player_id, _vicinity} = Gateway.enter(unique_name())

      assert {:error, :no_exit} = Gateway.move(player_id, :up, "plaza")
    end

    test "returns error if player not in block" do
      assert {:error, :not_found} =
               Gateway.move("nobody_#{:rand.uniform(100_000)}", :north, "plaza")
    end
  end

  describe "search/1" do
    test "returns :nothing or {:found, item}" do
      {player_id, _vicinity} = Gateway.enter(unique_name())

      result = Gateway.search(player_id)

      assert result == :nothing or match?({:found, _item}, result)
    end
  end
end
