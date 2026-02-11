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

  describe "block_name/1" do
    test "returns the display name for a block id" do
      assert "The Plaza" = WorldMap.block_name("plaza")
    end

    test "returns nil for an unknown block id" do
      assert nil == WorldMap.block_name("unknown")
    end
  end

  describe "block_type/1" do
    test "returns the type for a block id" do
      assert :square = WorldMap.block_type("plaza")
    end

    test "returns nil for an unknown block id" do
      assert nil == WorldMap.block_type("unknown")
    end
  end

  describe "surrounding/1" do
    test "returns 3x3 grid of block ids for a grid block" do
      grid = WorldMap.surrounding("plaza")

      assert [
               ["ashwell", "north_alley", "wormgarden"],
               ["west_street", "plaza", "east_street"],
               ["the_stray", "south_alley", "lame_horse"]
             ] = grid
    end

    test "returns parent's grid for an interior block" do
      grid = WorldMap.surrounding("lame_horse_interior")

      assert grid == WorldMap.surrounding("lame_horse")
    end

    test "returns nil for an unmapped block" do
      assert nil == WorldMap.surrounding("unknown")
    end

    test "pads with nils at edges" do
      grid = WorldMap.surrounding("ashwell")

      assert [
               [nil, nil, nil],
               [nil, "ashwell", "north_alley"],
               [nil, "west_street", "plaza"]
             ] = grid
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
