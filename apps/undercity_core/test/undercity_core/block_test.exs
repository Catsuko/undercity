defmodule UndercityCore.BlockTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Block
  alias UndercityCore.Person

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
    test "adds a person to the block" do
      block = Block.new("plaza", "The Plaza", :square)
      person = Person.new("Grimshaw")

      block = Block.add_person(block, person)

      assert MapSet.member?(block.people, person)
    end

    test "adding the same person twice does not duplicate" do
      block = Block.new("plaza", "The Plaza", :square)
      person = Person.new("Grimshaw")

      block =
        block
        |> Block.add_person(person)
        |> Block.add_person(person)

      assert MapSet.size(block.people) == 1
    end
  end

  describe "remove_person/2" do
    test "removes a person from the block" do
      block = Block.new("plaza", "The Plaza", :square)
      person = Person.new("Grimshaw")

      block =
        block
        |> Block.add_person(person)
        |> Block.remove_person(person)

      refute MapSet.member?(block.people, person)
    end

    test "removing a person not in the block is a no-op" do
      block = Block.new("plaza", "The Plaza", :square)
      person = Person.new("Grimshaw")

      block = Block.remove_person(block, person)

      assert block.people == MapSet.new()
    end
  end

  describe "find_person_by_name/2" do
    test "returns the person when found" do
      block = Block.new("plaza", "The Plaza", :square)
      person = Person.new("Grimshaw")

      block = Block.add_person(block, person)

      assert Block.find_person_by_name(block, "Grimshaw") == person
    end

    test "returns nil when not found" do
      block = Block.new("plaza", "The Plaza", :square)

      assert Block.find_person_by_name(block, "Nobody") == nil
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

  describe "exit/2" do
    test "returns the destination block id for a valid direction" do
      block = Block.new("plaza", "The Plaza", :square, %{north: "market"})

      assert Block.exit(block, :north) == {:ok, "market"}
    end

    test "returns :error for an invalid direction" do
      block = Block.new("plaza", "The Plaza", :square, %{north: "market"})

      assert Block.exit(block, :south) == :error
    end
  end

  describe "list_exits/1" do
    test "returns all exits as a list of direction-id pairs" do
      exits = %{north: "market", south: "catacombs"}
      block = Block.new("plaza", "The Plaza", nil, exits)

      result = Block.list_exits(block)

      assert length(result) == 2
      assert {:north, "market"} in result
      assert {:south, "catacombs"} in result
    end

    test "returns empty list when no exits" do
      block = Block.new("plaza", "The Plaza", :square)

      assert Block.list_exits(block) == []
    end
  end

  describe "inside?/1" do
    test "returns true when block has an exit direction" do
      block = Block.new("lame_horse_interior", "The Lame Horse Inn", :inn, %{exit: "lame_horse"})

      assert Block.inside?(block)
    end

    test "returns false when block has no exit direction" do
      block = Block.new("plaza", "The Plaza", :square, %{north: "north_alley"})

      refute Block.inside?(block)
    end
  end

  describe "list_people/1" do
    test "returns an empty list when no people" do
      block = Block.new("plaza", "The Plaza", :square)

      assert Block.list_people(block) == []
    end

    test "returns all people in the block" do
      block = Block.new("plaza", "The Plaza", :square)
      person1 = Person.new("Grimshaw")
      person2 = Person.new("Mordecai")

      block =
        block
        |> Block.add_person(person1)
        |> Block.add_person(person2)

      people = Block.list_people(block)

      assert length(people) == 2
      assert person1 in people
      assert person2 in people
    end
  end
end
