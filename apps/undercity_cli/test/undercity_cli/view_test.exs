defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View
  alias UndercityServer.Vicinity

  describe "describe_block/2" do
    test "includes grid, name, type-driven description, and people" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", "lame_horse"]
        ],
        building_type: nil
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "You are at"
      assert result =~ "The Plaza"
      assert result =~ "A wide, open space where the ground has been worn flat by countless feet."
      assert result =~ "Mordecai"
      refute result =~ "Grimshaw"
      assert result =~ "┌"
      assert result =~ "┘"
    end

    test "shows alone message when only current player is present" do
      vicinity = %Vicinity{
        id: "ashwell",
        type: :fountain,
        people: [%{id: "1", name: "Grimshaw"}],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "ashwell", "north_alley"],
          [nil, "west_street", "plaza"]
        ],
        building_type: nil
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "You are at"
      assert result =~ "Ashwell"
      assert result =~ "A stone basin sits at the centre of this space, dry and cracked."
      assert result =~ "You are alone here."
    end

    test "uses 'outside' prefix with building-type description for space blocks" do
      vicinity = %Vicinity{
        id: "lame_horse",
        type: :space,
        people: [],
        neighbourhood: [
          ["plaza", "east_street", nil],
          ["south_alley", "lame_horse", nil],
          [nil, nil, nil]
        ],
        building_type: :inn
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "You are outside"
      assert result =~ "The Lame Horse"
      assert result =~ "crooked timber frame"
      assert result =~ "┌"
    end

    test "falls back to generic space description when no building type" do
      vicinity = %Vicinity{
        id: "some_space",
        type: :space,
        people: [],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "some_space", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "A patch of open ground"
    end

    test "renders scribble when present" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", "lame_horse"]
        ],
        building_type: nil,
        scribble: "beware the dark"
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "Someone has scribbled"
      assert result =~ "beware the dark"
      assert result =~ "on the ground."
      # Italic ANSI codes
      assert result =~ "\e[3m"
    end

    test "does not render scribble line when nil" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", "lame_horse"]
        ],
        building_type: nil,
        scribble: nil
      }

      result = View.describe_block(vicinity, "Grimshaw")

      refute result =~ "scribbled"
    end

    test "scribble says 'on a tombstone' for graveyard" do
      vicinity = %Vicinity{
        id: "graveyard",
        type: :graveyard,
        people: [],
        neighbourhood: [[nil, nil, nil], [nil, "graveyard", nil], [nil, nil, nil]],
        building_type: nil,
        scribble: "rest in peace"
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "rest in peace"
      assert result =~ "on a tombstone."
    end

    test "scribble says 'on the wall' for inn blocks" do
      vicinity = %Vicinity{
        id: "lame_horse_interior",
        type: :inn,
        people: [],
        neighbourhood: [
          ["plaza", "east_street", nil],
          ["south_alley", "lame_horse", nil],
          [nil, nil, nil]
        ],
        building_type: nil,
        scribble: "free ale"
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "free ale"
      assert result =~ "on the wall."
    end

    test "scribble says 'on the wall' for space with building" do
      vicinity = %Vicinity{
        id: "lame_horse",
        type: :space,
        people: [],
        neighbourhood: [
          ["plaza", "east_street", nil],
          ["south_alley", "lame_horse", nil],
          [nil, nil, nil]
        ],
        building_type: :inn,
        scribble: "enter here"
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "enter here"
      assert result =~ "on the wall."
    end

    test "uses 'inside' prefix for inn blocks with dimmed grid" do
      vicinity = %Vicinity{
        id: "lame_horse_interior",
        type: :inn,
        people: [],
        neighbourhood: [
          ["plaza", "east_street", nil],
          ["south_alley", "lame_horse", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      result = View.describe_block(vicinity, "Grimshaw")

      assert result =~ "You are inside"
      assert result =~ "The Lame Horse Inn"
      assert result =~ "Low beams sag overhead"
      assert result =~ "┌"
    end
  end

  describe "render_grid/2" do
    test "renders center block with all neighbours" do
      neighbourhood = [
        ["ashwell", "north_alley", "wormgarden"],
        ["west_street", "plaza", "east_street"],
        ["the_stray", "south_alley", "lame_horse"]
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
        [nil, "ashwell", "north_alley"],
        [nil, "west_street", "plaza"]
      ]

      result = View.render_grid(neighbourhood)

      assert result =~ "Ashwell"
      assert result =~ "North Alley"
      assert result =~ "West Street"
      assert result =~ "The Plaza"
    end

    test "renders building box around building cells" do
      neighbourhood = [
        ["plaza", "east_street", nil],
        ["south_alley", "lame_horse", nil],
        [nil, nil, nil]
      ]

      result = View.render_grid(neighbourhood)

      assert result =~ "╔"
      assert result =~ "║"
      assert result =~ "╚"
      assert result =~ "The Lame Horse"
    end

    test "does not render building box around normal cells" do
      neighbourhood = [
        ["ashwell", "north_alley", "wormgarden"],
        ["west_street", "plaza", "east_street"],
        ["the_stray", "south_alley", nil]
      ]

      result = View.render_grid(neighbourhood)

      refute result =~ "╔"
      refute result =~ "║"
      refute result =~ "╚"
    end

    test "dims grid and fills building box when inside" do
      neighbourhood = [
        ["plaza", "east_street", nil],
        ["south_alley", "lame_horse", nil],
        [nil, nil, nil]
      ]

      result = View.render_grid(neighbourhood, "lame_horse")

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
      people = [%{id: "1", name: "Grimshaw"}]

      assert View.describe_people(people, "Grimshaw") == "You are alone here."
    end

    test "shows alone message when no one is present" do
      assert View.describe_people([], "Grimshaw") == "You are alone here."
    end

    test "lists other players, excluding the current player" do
      people = [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}]

      assert View.describe_people(people, "Grimshaw") == "Present: Mordecai"
    end

    test "lists multiple other players" do
      people = [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}, %{id: "3", name: "Vesper"}]

      result = View.describe_people(people, "Grimshaw")

      assert result =~ "Mordecai"
      assert result =~ "Vesper"
      refute result =~ "Grimshaw"
    end
  end

  describe "format_message/2" do
    test "formats info message with icon" do
      result = View.format_message("You find nothing.")

      assert result =~ "▸ You find nothing."
      assert result =~ "\e[38;5;67m"
    end

    test "formats success message in green" do
      result = View.format_message("You found Junk!", :success)

      assert result =~ "▸ You found Junk!"
      assert result =~ "\e[38;5;108m"
    end

    test "formats warning message in red" do
      result = View.format_message("You can't go that way.", :warning)

      assert result =~ "▸ You can't go that way."
      assert result =~ "\e[38;5;131m"
    end
  end

  describe "awareness_tier/1" do
    test "40+ is rested" do
      assert :rested = View.awareness_tier(50)
      assert :rested = View.awareness_tier(40)
    end

    test "16-39 is weary" do
      assert :weary = View.awareness_tier(39)
      assert :weary = View.awareness_tier(16)
    end

    test "1-15 is exhausted" do
      assert :exhausted = View.awareness_tier(15)
      assert :exhausted = View.awareness_tier(1)
    end

    test "0 is spent" do
      assert :spent = View.awareness_tier(0)
    end
  end

  describe "status_message/1" do
    test "rested is a success message" do
      assert {"You feel rested.", :success} = View.status_message(50)
    end

    test "weary is a warning message" do
      assert {"You feel weary.", :warning} = View.status_message(30)
    end

    test "exhausted is a warning message" do
      assert {"You can barely keep your eyes open.", :warning} = View.status_message(10)
    end

    test "spent is a warning message" do
      assert {"You are completely exhausted.", :warning} = View.status_message(0)
    end
  end

  describe "threshold_message/2" do
    test "returns message when crossing into weary" do
      assert {"You feel weary.", :warning} = View.threshold_message(40, 39)
    end

    test "returns message when crossing into exhausted" do
      assert {"You can barely keep your eyes open.", :warning} = View.threshold_message(16, 15)
    end

    test "returns message when crossing into spent" do
      assert {"You are completely exhausted.", :warning} = View.threshold_message(1, 0)
    end

    test "returns message when recovering to rested" do
      assert {"You feel rested.", :success} = View.threshold_message(39, 40)
    end

    test "returns nil when staying in same tier" do
      assert nil == View.threshold_message(50, 49)
      assert nil == View.threshold_message(30, 20)
    end
  end
end
