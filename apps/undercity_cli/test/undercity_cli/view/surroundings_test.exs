defmodule UndercityCli.View.SurroundingsTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias UndercityCli.View.Surroundings
  alias UndercityServer.Vicinity

  describe "render/1" do
    test "renders center block with all neighbours" do
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

      output = capture_io(fn -> Surroundings.render(vicinity) end)

      assert output =~ "The Plaza"
      assert output =~ "Ashwell"
      assert output =~ "North Alley"
      assert output =~ "West Street"
      assert output =~ "East Street"
      assert output =~ "┌"
      assert output =~ "┘"
    end

    test "renders empty cells as blank spaces for corner blocks" do
      vicinity = %Vicinity{
        id: "ashwell",
        type: :fountain,
        people: [],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "ashwell", "north_alley"],
          [nil, "west_street", "plaza"]
        ],
        building_type: nil
      }

      output = capture_io(fn -> Surroundings.render(vicinity) end)

      assert output =~ "Ashwell"
      assert output =~ "North Alley"
      assert output =~ "West Street"
      assert output =~ "The Plaza"
    end

    test "renders building box around building cells" do
      vicinity = %Vicinity{
        id: "south_alley",
        type: :street,
        people: [],
        neighbourhood: [
          ["plaza", "east_street", nil],
          ["south_alley", "lame_horse", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      output = capture_io(fn -> Surroundings.render(vicinity) end)

      assert output =~ "╔"
      assert output =~ "║"
      assert output =~ "╚"
      assert output =~ "The Lame Horse"
    end

    test "does not render building box around normal cells" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", nil]
        ],
        building_type: nil
      }

      output = capture_io(fn -> Surroundings.render(vicinity) end)

      refute output =~ "╔"
      refute output =~ "║"
      refute output =~ "╚"
    end

    test "dims grid and fills building box when inside" do
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

      output = capture_io(fn -> Surroundings.render(vicinity) end)

      # Dim colour used for grid lines
      assert output =~ "\e[38;5;235m"
      # Background fill inside the building box
      assert output =~ "\e[48;5;236m"
      # Building box characters still present
      assert output =~ "╔"
      assert output =~ "║"
    end

    test "does nothing when no neighbourhood" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: nil,
        building_type: nil
      }

      output = capture_io(fn -> Surroundings.render(vicinity) end)

      assert output == ""
    end
  end
end
