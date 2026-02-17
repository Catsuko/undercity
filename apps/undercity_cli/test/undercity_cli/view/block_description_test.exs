defmodule UndercityCli.View.BlockDescriptionTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.BlockDescription
  alias UndercityServer.Vicinity

  describe "render_to_string/2" do
    test "includes name, type-driven description, and people" do
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "You are at"
      assert output =~ "The Plaza"
      assert output =~ "A wide, open space where the ground has been worn flat by countless feet."
      assert output =~ "Mordecai"
      refute output =~ "Grimshaw"
    end

    test "does not include the neighbourhood grid" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", "lame_horse"]
        ],
        building_type: nil
      }

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      refute output =~ "┌"
      refute output =~ "┘"
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "You are at"
      assert output =~ "Ashwell"
      assert output =~ "A stone basin sits at the centre of this space, dry and cracked."
      assert output =~ "You are alone here."
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "You are outside"
      assert output =~ "The Lame Horse"
      assert output =~ "crooked timber frame"
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "A patch of open ground"
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "Someone has scribbled"
      assert output =~ "beware the dark"
      assert output =~ "on the ground."
      # Italic ANSI codes
      assert output =~ "\e[3m"
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      refute output =~ "scribbled"
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "rest in peace"
      assert output =~ "on a tombstone."
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "free ale"
      assert output =~ "on the wall."
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "enter here"
      assert output =~ "on the wall."
    end

    test "uses 'inside' prefix for inn blocks" do
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

      output = BlockDescription.render_to_string(vicinity, "Grimshaw")

      assert output =~ "You are inside"
      assert output =~ "The Lame Horse Inn"
      assert output =~ "Low beams sag overhead"
    end
  end

  describe "describe_people/2" do
    test "shows alone message when only the current player is present" do
      people = [%{id: "1", name: "Grimshaw"}]

      assert BlockDescription.describe_people(people, "Grimshaw") == "You are alone here."
    end

    test "shows alone message when no one is present" do
      assert BlockDescription.describe_people([], "Grimshaw") == "You are alone here."
    end

    test "lists other players, excluding the current player" do
      people = [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}]

      assert BlockDescription.describe_people(people, "Grimshaw") == "Present: Mordecai"
    end

    test "lists multiple other players" do
      people = [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}, %{id: "3", name: "Vesper"}]

      result = BlockDescription.describe_people(people, "Grimshaw")

      assert result =~ "Mordecai"
      assert result =~ "Vesper"
      refute result =~ "Grimshaw"
    end
  end
end
