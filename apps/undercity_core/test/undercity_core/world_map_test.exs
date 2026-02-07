defmodule UndercityCore.WorldMapTest do
  use ExUnit.Case, async: true

  alias UndercityCore.WorldMap

  describe "neighbourhood/1" do
    test "returns full grid for center block" do
      assert {:ok, grid} = WorldMap.neighbourhood("plaza")

      assert grid == [
               ["Ashwell", "North Alley", "Wormgarden"],
               ["West Street", "The Plaza", "East Street"],
               ["The Stray", "South Alley", "The Lame Horse Inn"]
             ]
    end

    test "returns nils for out-of-bounds cells at northwest corner" do
      assert {:ok, grid} = WorldMap.neighbourhood("ashwell")

      assert grid == [
               [nil, nil, nil],
               [nil, "Ashwell", "North Alley"],
               [nil, "West Street", "The Plaza"]
             ]
    end

    test "returns nils for out-of-bounds cells at southeast corner" do
      assert {:ok, grid} = WorldMap.neighbourhood("lame_horse")

      assert grid == [
               ["The Plaza", "East Street", nil],
               ["South Alley", "The Lame Horse Inn", nil],
               [nil, nil, nil]
             ]
    end

    test "returns nils for out-of-bounds cells at edge" do
      assert {:ok, grid} = WorldMap.neighbourhood("north_alley")

      assert grid == [
               [nil, nil, nil],
               ["Ashwell", "North Alley", "Wormgarden"],
               ["West Street", "The Plaza", "East Street"]
             ]
    end

    test "returns error for unknown block" do
      assert :error = WorldMap.neighbourhood("unknown_block")
    end
  end

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
  end
end
