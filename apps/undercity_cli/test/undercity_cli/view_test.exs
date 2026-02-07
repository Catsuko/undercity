defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View
  alias UndercityCore.Person

  describe "describe_block/2" do
    test "includes name, description, people, and exits" do
      block_info = %{
        name: "The Plaza",
        description: "The central gathering place.",
        people: [Person.new("Grimshaw"), Person.new("Mordecai")],
        exits: [north: "north_alley", south: "south_alley"]
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "The Plaza"
      assert result =~ "The central gathering place."
      assert result =~ "Mordecai"
      refute result =~ "Grimshaw"
      assert result =~ "Exits: north, south"
    end

    test "shows alone message when only current player is present" do
      block_info = %{
        name: "A Dark Corridor",
        description: "A dark corridor.",
        people: [Person.new("Grimshaw")],
        exits: []
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "A Dark Corridor"
      assert result =~ "A dark corridor."
      assert result =~ "You are alone here."
      assert result =~ "There are no exits."
    end
  end

  describe "describe_people/2" do
    test "shows alone message when only the current player is present" do
      people = [Person.new("Grimshaw")]

      assert View.describe_people(people, "Grimshaw") == "You are alone here."
    end

    test "shows alone message when no one is present" do
      assert View.describe_people([], "Grimshaw") == "You are alone here."
    end

    test "lists other players, excluding the current player" do
      people = [Person.new("Grimshaw"), Person.new("Mordecai")]

      assert View.describe_people(people, "Grimshaw") == "Present: Mordecai"
    end

    test "lists multiple other players" do
      people = [Person.new("Grimshaw"), Person.new("Mordecai"), Person.new("Vesper")]

      result = View.describe_people(people, "Grimshaw")

      assert result =~ "Mordecai"
      assert result =~ "Vesper"
      refute result =~ "Grimshaw"
    end
  end

  describe "describe_exits/1" do
    test "shows available exits" do
      assert View.describe_exits(north: "market", east: "alley") == "Exits: north, east"
    end

    test "shows single exit" do
      assert View.describe_exits(south: "catacombs") == "Exits: south"
    end

    test "shows no exits message when empty" do
      assert View.describe_exits([]) == "There are no exits."
    end
  end
end
