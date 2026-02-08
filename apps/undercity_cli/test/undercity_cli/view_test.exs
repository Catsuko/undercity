defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View
  alias UndercityCore.Person

  describe "describe_block/2" do
    test "includes grid, name, type-driven description, and people" do
      block_info = %{
        name: "The Plaza",
        type: :square,
        people: [Person.new("Grimshaw"), Person.new("Mordecai")],
        neighbourhood: [
          ["Ashwell", "North Alley", "Wormgarden"],
          ["West Street", "The Plaza", "East Street"],
          ["The Stray", "South Alley", "The Lame Horse Inn"]
        ]
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "You are at"
      assert result =~ "The Plaza"
      assert result =~ "A wide, open space where the ground has been worn flat by countless feet."
      assert result =~ "Mordecai"
      refute result =~ "Grimshaw"
      assert result =~ "┌"
      assert result =~ "┘"
    end

    test "shows alone message when only current player is present" do
      block_info = %{
        name: "Ashwell",
        type: :fountain,
        people: [Person.new("Grimshaw")],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "Ashwell", "North Alley"],
          [nil, "West Street", "The Plaza"]
        ]
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "You are at"
      assert result =~ "Ashwell"
      assert result =~ "A stone basin sits at the centre of this space, dry and cracked."
      assert result =~ "You are alone here."
    end
  end

  describe "render_grid/1" do
    test "renders center block with all neighbours" do
      neighbourhood = [
        ["Ashwell", "North Alley", "Wormgarden"],
        ["West Street", "The Plaza", "East Street"],
        ["The Stray", "South Alley", "The Lame Horse Inn"]
      ]

      result = View.render_grid(neighbourhood)

      assert result =~ "The Plaza"
      assert result =~ "Ashwell"
      assert result =~ "North Alley"
      assert result =~ "West Street"
      assert result =~ "East Street"
      assert result =~ "┌"
      assert result =~ "┘"
    end

    test "renders empty cells as blank spaces for corner blocks" do
      neighbourhood = [
        [nil, nil, nil],
        [nil, "Ashwell", "North Alley"],
        [nil, "West Street", "The Plaza"]
      ]

      result = View.render_grid(neighbourhood)

      assert result =~ "Ashwell"
      assert result =~ "North Alley"
      assert result =~ "West Street"
      assert result =~ "The Plaza"
    end

    test "renders empty cells for edge blocks" do
      neighbourhood = [
        ["North Alley", "Wormgarden", nil],
        ["The Plaza", "East Street", nil],
        ["South Alley", "The Lame Horse Inn", nil]
      ]

      result = View.render_grid(neighbourhood)

      assert result =~ "East Street"
      assert result =~ "Wormgarden"
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
end
