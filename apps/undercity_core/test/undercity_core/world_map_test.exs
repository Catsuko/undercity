defmodule UndercityCore.WorldMapTest do
  use ExUnit.Case, async: true

  alias UndercityCore.WorldMap

  describe "resolve_exit/2" do
    test "returns destination block id for valid exit" do
      assert {:ok, "wardens_archive"} = WorldMap.resolve_exit("ashwarden_square", :north)
    end

    test "returns error for invalid direction" do
      assert :error = WorldMap.resolve_exit("wormgarden", :north)
    end

    test "returns error for unknown block" do
      assert :error = WorldMap.resolve_exit("unknown", :north)
    end
  end

  describe "block_name/1" do
    test "returns the display name for a block id" do
      assert "Ashwarden Square" = WorldMap.block_name("ashwarden_square")
    end

    test "returns nil for an unknown block id" do
      assert nil == WorldMap.block_name("unknown")
    end
  end

  describe "block_type/1" do
    test "returns the type for a block id" do
      assert :square = WorldMap.block_type("ashwarden_square")
    end

    test "returns nil for an unknown block id" do
      assert nil == WorldMap.block_type("unknown")
    end
  end

  describe "surrounding/1" do
    test "returns 3x3 grid of block ids for a grid block" do
      grid = WorldMap.surrounding("ashwarden_square")

      assert [
               ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
               ["aldermans_well", "ashwarden_square", "needle_lane"],
               ["broad_alley", "coin_street", "cut_passage"]
             ] = grid
    end

    test "returns nil for an unmapped block" do
      assert nil == WorldMap.surrounding("unknown")
    end

    test "pads with nils at edges" do
      grid = WorldMap.surrounding("wormgarden")

      assert [
               [nil, nil, nil],
               [nil, "wormgarden", "hollow_house"],
               [nil, "sextons_close", "sextons_row"]
             ] = grid
    end
  end

  describe "building_type/1" do
    test "returns nil for a block without a building" do
      assert nil == WorldMap.building_type("ashwarden_square")
    end
  end
end
