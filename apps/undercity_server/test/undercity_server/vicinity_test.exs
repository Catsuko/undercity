defmodule UndercityServer.VicinityTest do
  use ExUnit.Case, async: true

  alias UndercityServer.Vicinity

  describe "new/2" do
    test "builds a vicinity centred on the given block" do
      vicinity = Vicinity.new("ashwarden_square", [])

      assert vicinity.id == "ashwarden_square"
      assert vicinity.type == :square
      assert vicinity.people == []
      assert vicinity.building_type == nil

      assert [
               ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
               ["aldermans_well", "ashwarden_square", "needle_lane"],
               ["broad_alley", "coin_street", "cut_passage"]
             ] = vicinity.neighbourhood
    end

    test "includes scribble when provided" do
      vicinity = Vicinity.new("ashwarden_square", [], scribble: "hello world")

      assert vicinity.scribble == "hello world"
    end

    test "scribble defaults to nil" do
      vicinity = Vicinity.new("ashwarden_square", [])

      assert vicinity.scribble == nil
    end
  end

  describe "name/1" do
    test "returns the block name for a regular block" do
      vicinity = Vicinity.new("ashwarden_square", [])

      assert Vicinity.name(vicinity) == "Ashwarden Square"
    end
  end

  describe "name_for/1" do
    test "returns the block name" do
      assert Vicinity.name_for("ashwarden_square") == "Ashwarden Square"
    end

    test "falls back to block id for unknown blocks" do
      assert Vicinity.name_for("unknown") == "unknown"
    end
  end

  describe "inside?/1" do
    test "returns false for a regular block" do
      vicinity = Vicinity.new("ashwarden_square", [])

      refute Vicinity.inside?(vicinity)
    end
  end

  describe "building?/1" do
    test "returns false for a non-building block" do
      refute Vicinity.building?("ashwarden_square")
    end
  end
end
