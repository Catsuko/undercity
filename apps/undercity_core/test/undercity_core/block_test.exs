defmodule UndercityCore.BlockTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Block

  describe "new/3" do
    test "creates a block with id, name, and type" do
      block = Block.new("plaza", "The Plaza", :square)

      assert block.id == "plaza"
      assert block.name == "The Plaza"
      assert block.type == :square
      assert block.people == MapSet.new()
    end
  end

  describe "add_person/2" do
    test "adds a player id to the block" do
      block = Block.new("plaza", "The Plaza", :square)

      block = Block.add_person(block, "player_abc")

      assert MapSet.member?(block.people, "player_abc")
    end

    test "adding the same player id twice does not duplicate" do
      block = Block.new("plaza", "The Plaza", :square)

      block =
        block
        |> Block.add_person("player_abc")
        |> Block.add_person("player_abc")

      assert MapSet.size(block.people) == 1
    end
  end

  describe "remove_person/2" do
    test "removes a player id from the block" do
      block = Block.new("plaza", "The Plaza", :square)

      block =
        block
        |> Block.add_person("player_abc")
        |> Block.remove_person("player_abc")

      refute MapSet.member?(block.people, "player_abc")
    end

    test "removing a player id not in the block is a no-op" do
      block = Block.new("plaza", "The Plaza", :square)

      block = Block.remove_person(block, "player_abc")

      assert block.people == MapSet.new()
    end
  end

  describe "has_person?/2" do
    test "returns true when player id is present" do
      block = Block.new("plaza", "The Plaza", :square)
      block = Block.add_person(block, "player_abc")

      assert Block.has_person?(block, "player_abc")
    end

    test "returns false when player id is not present" do
      block = Block.new("plaza", "The Plaza", :square)

      refute Block.has_person?(block, "player_abc")
    end
  end

  describe "new/4" do
    test "creates a block with exits" do
      exits = %{north: "market", south: "catacombs"}
      block = Block.new("plaza", "The Plaza", :square, exits)

      assert block.exits == exits
    end

    test "exits default to empty map" do
      block = Block.new("plaza", "The Plaza", :square)

      assert block.exits == %{}
    end

    test "creates a block with enter and exit directions" do
      exits = %{enter: "inn_interior", exit: "inn_exterior"}
      block = Block.new("inn", "The Inn", :space, exits)

      assert block.exits == exits
    end
  end

  describe "list_people/1" do
    test "returns an empty list when no people" do
      block = Block.new("plaza", "The Plaza", :square)

      assert Block.list_people(block) == []
    end

    test "returns all player ids in the block" do
      block = Block.new("plaza", "The Plaza", :square)

      block =
        block
        |> Block.add_person("player_abc")
        |> Block.add_person("player_xyz")

      people = Block.list_people(block)

      assert length(people) == 2
      assert "player_abc" in people
      assert "player_xyz" in people
    end
  end
end
