defmodule UndercityServer.VicinityTest do
  use ExUnit.Case, async: true

  alias UndercityServer.Vicinity

  describe "new/2" do
    test "builds a vicinity centred on the given block" do
      vicinity = Vicinity.new("plaza", [])

      assert vicinity.id == "plaza"
      assert vicinity.type == :square
      assert vicinity.people == []
      assert vicinity.building_type == nil

      assert [
               ["ashwell", "north_alley", "wormgarden"],
               ["west_street", "plaza", "east_street"],
               ["the_stray", "south_alley", "lame_horse"]
             ] = vicinity.neighbourhood
    end

    test "includes building type for blocks with buildings" do
      vicinity = Vicinity.new("lame_horse", [])

      assert vicinity.building_type == :inn
    end

    test "inherits parent neighbourhood for interior blocks" do
      exterior = Vicinity.new("lame_horse", [])
      interior = Vicinity.new("lame_horse_interior", [])

      assert interior.neighbourhood == exterior.neighbourhood
    end

    test "includes scribble when provided" do
      vicinity = Vicinity.new("plaza", [], scribble: "hello world")

      assert vicinity.scribble == "hello world"
    end

    test "scribble defaults to nil" do
      vicinity = Vicinity.new("plaza", [])

      assert vicinity.scribble == nil
    end
  end

  describe "name/1" do
    test "returns the block name for a regular block" do
      vicinity = Vicinity.new("plaza", [])

      assert Vicinity.name(vicinity) == "The Plaza"
    end

    test "appends building type for buildings" do
      vicinity = Vicinity.new("lame_horse", [])

      assert Vicinity.name(vicinity) == "The Lame Horse Inn"
    end

    test "returns name of parent block for interior blocks" do
      vicinity = Vicinity.new("lame_horse_interior", [])

      assert Vicinity.name(vicinity) == "The Lame Horse Inn"
    end
  end

  describe "name_for/1" do
    test "returns the block name" do
      assert Vicinity.name_for("plaza") == "The Plaza"
    end

    test "appends building type for buildings" do
      assert Vicinity.name_for("lame_horse") == "The Lame Horse Inn"
    end

    test "falls back to block id for unknown blocks" do
      assert Vicinity.name_for("unknown") == "unknown"
    end
  end

  describe "inside?/1" do
    test "returns true when inside a building" do
      vicinity = Vicinity.new("lame_horse_interior", [])

      assert Vicinity.inside?(vicinity)
    end

    test "returns false when outside a building" do
      vicinity = Vicinity.new("lame_horse", [])

      refute Vicinity.inside?(vicinity)
    end

    test "returns false for a regular block" do
      vicinity = Vicinity.new("plaza", [])

      refute Vicinity.inside?(vicinity)
    end
  end

  describe "building?/1" do
    test "returns true for a building block" do
      assert Vicinity.building?("lame_horse")
    end

    test "returns false for a non-building block" do
      refute Vicinity.building?("plaza")
    end
  end
end
