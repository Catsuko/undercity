defmodule UndercityCore.WorldMapTest do
  use ExUnit.Case, async: true

  alias UndercityCore.WorldMap

  describe "neighbourhood/1" do
    test "returns full grid for center block" do
      result = WorldMap.neighbourhood("plaza")

      assert result == [
               ["Ashwell", "North Alley", "Wormgarden"],
               ["West Street", "The Plaza", "East Street"],
               ["The Stray", "South Alley", "The Lame Horse Inn"]
             ]
    end

    test "returns nils for out-of-bounds cells at northwest corner" do
      result = WorldMap.neighbourhood("ashwell")

      assert result == [
               [nil, nil, nil],
               [nil, "Ashwell", "North Alley"],
               [nil, "West Street", "The Plaza"]
             ]
    end

    test "returns nils for out-of-bounds cells at southeast corner" do
      result = WorldMap.neighbourhood("lame_horse")

      assert result == [
               ["The Plaza", "East Street", nil],
               ["South Alley", "The Lame Horse Inn", nil],
               [nil, nil, nil]
             ]
    end

    test "returns nils for out-of-bounds cells at edge" do
      result = WorldMap.neighbourhood("north_alley")

      assert result == [
               [nil, nil, nil],
               ["Ashwell", "North Alley", "Wormgarden"],
               ["West Street", "The Plaza", "East Street"]
             ]
    end
  end
end
