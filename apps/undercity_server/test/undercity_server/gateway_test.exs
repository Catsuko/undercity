defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Gateway
  alias UndercityServer.Vicinity

  defp unique_name, do: "player_#{:rand.uniform(100_000)}"

  describe "enter/1" do
    test "creates a person and spawns them in the plaza" do
      name = unique_name()
      %Vicinity{} = vicinity = Gateway.enter(name)

      assert vicinity.id == "plaza"
      assert vicinity.type == :square
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "multiple people can enter" do
      name1 = unique_name()
      name2 = unique_name()
      Gateway.enter(name1)
      %Vicinity{} = vicinity = Gateway.enter(name2)

      names = Enum.map(vicinity.people, & &1.name)
      assert name1 in names
      assert name2 in names
    end

    test "entering with the same name does not create a duplicate" do
      name = unique_name()
      Gateway.enter(name)
      %Vicinity{} = vicinity = Gateway.enter(name)

      matches = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(matches) == 1
    end

    test "reconnects to the block the player is already in" do
      name = unique_name()
      Gateway.enter(name)
      {:ok, _} = Gateway.move(name, :north, "plaza")

      %Vicinity{} = vicinity = Gateway.enter(name)

      assert vicinity.id == "north_alley"
    end
  end

  describe "move/3" do
    test "moves a player to an adjacent block" do
      name = unique_name()
      Gateway.enter(name)

      {:ok, %Vicinity{} = vicinity} = Gateway.move(name, :north, "plaza")

      assert vicinity.id == "north_alley"
      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "player is removed from the source block" do
      name = unique_name()
      Gateway.enter(name)

      {:ok, _} = Gateway.move(name, :north, "plaza")

      {"plaza", people} = UndercityServer.Block.info("plaza")
      refute Enum.any?(people, fn p -> p.name == name end)
    end

    test "returns error for invalid direction" do
      name = unique_name()
      Gateway.enter(name)

      assert {:error, :no_exit} = Gateway.move(name, :up, "plaza")
    end

    test "returns error if player not in block" do
      assert {:error, :not_found} =
               Gateway.move("nobody_#{:rand.uniform(100_000)}", :north, "plaza")
    end
  end
end
