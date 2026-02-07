defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Gateway

  describe "enter/1" do
    test "creates a person and spawns them in the plaza" do
      info = Gateway.enter("Grimshaw")

      assert info.id == "plaza"
      assert info.name == "The Plaza"
      assert info.description == "The central gathering place of the undercity."
      assert Enum.any?(info.people, fn p -> p.name == "Grimshaw" end)
    end

    test "multiple people can enter" do
      Gateway.enter("Grimshaw")
      info = Gateway.enter("Mordecai")

      names = Enum.map(info.people, & &1.name)
      assert "Grimshaw" in names
      assert "Mordecai" in names
    end

    test "entering with the same name does not create a duplicate" do
      Gateway.enter("Grimshaw")
      info = Gateway.enter("Grimshaw")

      grimshaws = Enum.filter(info.people, fn p -> p.name == "Grimshaw" end)
      assert length(grimshaws) == 1
    end
  end

  describe "move/3" do
    test "moves a player to an adjacent block" do
      Gateway.enter("Grimshaw")

      {:ok, info} = Gateway.move("Grimshaw", :north, "plaza")

      assert info.id == "north_alley"
      assert Enum.any?(info.people, fn p -> p.name == "Grimshaw" end)
    end

    test "player is removed from the source block" do
      Gateway.enter("Grimshaw")

      {:ok, _} = Gateway.move("Grimshaw", :north, "plaza")

      plaza_info = UndercityServer.Block.info("plaza")
      refute Enum.any?(plaza_info.people, fn p -> p.name == "Grimshaw" end)
    end

    test "returns error for invalid direction" do
      Gateway.enter("Grimshaw")

      assert {:error, :no_exit} = Gateway.move("Grimshaw", :up, "plaza")
    end

    test "returns error if player not in block" do
      assert {:error, :not_found} = Gateway.move("Nobody", :north, "plaza")
    end
  end
end
