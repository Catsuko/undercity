defmodule UndercityCore.WorldMapTest do
  use ExUnit.Case, async: true

  alias UndercityCore.WorldMap

  describe "resolve_exit/2" do
    test "returns destination block id for valid exit" do
      assert {:ok, "north_alley"} = WorldMap.resolve_exit("plaza", :north)
    end

    test "returns error for invalid direction" do
      assert :error = WorldMap.resolve_exit("ashwell", :north)
    end

    test "returns error for unknown block" do
      assert :error = WorldMap.resolve_exit("unknown", :north)
    end

    test "resolves enter direction to interior block" do
      assert {:ok, "lame_horse_interior"} = WorldMap.resolve_exit("lame_horse", :enter)
    end

    test "resolves exit direction from interior to exterior" do
      assert {:ok, "lame_horse"} = WorldMap.resolve_exit("lame_horse_interior", :exit)
    end
  end

  describe "building_names/0" do
    test "includes blocks with enter exits" do
      names = WorldMap.building_names()

      assert MapSet.member?(names, "The Lame Horse")
    end

    test "does not include blocks without enter exits" do
      names = WorldMap.building_names()

      refute MapSet.member?(names, "The Plaza")
    end
  end

  describe "building_type/1" do
    test "returns interior block type for a block with a building" do
      assert :inn = WorldMap.building_type("lame_horse")
    end

    test "returns nil for a block without a building" do
      assert nil == WorldMap.building_type("plaza")
    end
  end
end
