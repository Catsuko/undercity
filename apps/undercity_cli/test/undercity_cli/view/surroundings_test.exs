defmodule UndercityCli.View.SurroundingsTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.Surroundings
  alias UndercityServer.Vicinity

  defp render_to_string(data), do: data |> Owl.Data.to_chardata() |> IO.iodata_to_binary()

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

      output = vicinity |> Surroundings.render() |> render_to_string()

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

      output = vicinity |> Surroundings.render() |> render_to_string()

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

      output = vicinity |> Surroundings.render() |> render_to_string()

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

      output = vicinity |> Surroundings.render() |> render_to_string()

      refute output =~ "╔"
      refute output =~ "║"
      refute output =~ "╚"
    end

    test "dims grid and highlights building box when inside" do
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

      output = vicinity |> Surroundings.render() |> render_to_string()

      # Dim colour used for non-building cells
      assert output =~ "\e[38;5;235m"
      # Highlight colour used for building box
      assert output =~ "\e[38;5;103m"
      # Building box characters still present
      assert output =~ "╔"
      assert output =~ "║"
    end

    test "returns empty string when no neighbourhood" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: nil,
        building_type: nil
      }

      assert Surroundings.render(vicinity) == ""
    end
  end
end
