defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View
  alias UndercityCore.Person

  @buildings MapSet.new(["The Lame Horse"])

  describe "describe_block/2" do
    test "includes grid, name, type-driven description, and people" do
      block_info = %{
        name: "The Plaza",
        type: :square,
        people: [Person.new("Grimshaw"), Person.new("Mordecai")],
        neighbourhood: [
          ["Ashwell", "North Alley", "Wormgarden"],
          ["West Street", "The Plaza", "East Street"],
          ["The Stray", "South Alley", "The Lame Horse"]
        ],
        buildings: @buildings,
        inside: nil,
        building_type: nil
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
        ],
        buildings: @buildings,
        inside: nil,
        building_type: nil
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "You are at"
      assert result =~ "Ashwell"
      assert result =~ "A stone basin sits at the centre of this space, dry and cracked."
      assert result =~ "You are alone here."
    end

    test "uses 'outside' prefix with building-type description for space blocks" do
      block_info = %{
        name: "The Lame Horse",
        type: :space,
        people: [],
        neighbourhood: [
          ["The Plaza", "East Street", nil],
          ["South Alley", "The Lame Horse", nil],
          [nil, nil, nil]
        ],
        buildings: @buildings,
        inside: nil,
        building_type: :inn
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "You are outside"
      assert result =~ "The Lame Horse"
      assert result =~ "crooked timber frame"
      assert result =~ "┌"
    end

    test "falls back to generic space description when no building type" do
      block_info = %{
        name: "Some Space",
        type: :space,
        people: [],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "Some Space", nil],
          [nil, nil, nil]
        ],
        buildings: MapSet.new(),
        inside: nil,
        building_type: nil
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "A patch of open ground"
    end

    test "uses 'inside' prefix for inn blocks with dimmed grid" do
      block_info = %{
        name: "The Lame Horse Inn",
        type: :inn,
        people: [],
        neighbourhood: [
          ["The Plaza", "East Street", nil],
          ["South Alley", "The Lame Horse", nil],
          [nil, nil, nil]
        ],
        buildings: @buildings,
        inside: "The Lame Horse",
        building_type: nil
      }

      result = View.describe_block(block_info, "Grimshaw")

      assert result =~ "You are inside"
      assert result =~ "The Lame Horse Inn"
      assert result =~ "Low beams sag overhead"
      assert result =~ "┌"
    end
  end

  describe "render_grid/3" do
    test "renders center block with all neighbours" do
      neighbourhood = [
        ["Ashwell", "North Alley", "Wormgarden"],
        ["West Street", "The Plaza", "East Street"],
        ["The Stray", "South Alley", "The Lame Horse"]
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

    test "renders building box around building cells" do
      neighbourhood = [
        ["The Plaza", "East Street", nil],
        ["South Alley", "The Lame Horse", nil],
        [nil, nil, nil]
      ]

      result = View.render_grid(neighbourhood, @buildings)

      assert result =~ "╔"
      assert result =~ "║"
      assert result =~ "╚"
      assert result =~ "The Lame Horse"
    end

    test "does not render building box around normal cells" do
      neighbourhood = [
        ["Ashwell", "North Alley", "Wormgarden"],
        ["West Street", "The Plaza", "East Street"],
        ["The Stray", "South Alley", nil]
      ]

      result = View.render_grid(neighbourhood, MapSet.new())

      refute result =~ "╔"
      refute result =~ "║"
      refute result =~ "╚"
    end

    test "dims grid and fills building box when inside" do
      neighbourhood = [
        ["The Plaza", "East Street", nil],
        ["South Alley", "The Lame Horse", nil],
        [nil, nil, nil]
      ]

      result = View.render_grid(neighbourhood, @buildings, "The Lame Horse")

      # Dim colour used for grid lines
      assert result =~ "\e[38;5;235m"
      # Background fill inside the building box
      assert result =~ "\e[48;5;236m"
      # Building box characters still present
      assert result =~ "╔"
      assert result =~ "║"
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
