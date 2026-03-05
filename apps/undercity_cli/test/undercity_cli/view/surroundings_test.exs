defmodule UndercityCli.View.SurroundingsTest do
  use ExUnit.Case, async: true

  alias Ratatouille.Renderer.Element
  alias UndercityCli.View.Surroundings
  alias UndercityServer.Vicinity

  defp all_cells(elements) when is_list(elements), do: Enum.flat_map(elements, &all_cells/1)
  defp all_cells(%Element{tag: :text, attributes: attrs}), do: [attrs]
  defp all_cells(%Element{children: children}), do: Enum.flat_map(children, &all_cells/1)

  defp all_text(element_or_list), do: element_or_list |> all_cells() |> Enum.map_join("", & &1.content)

  defp find_cell(element_or_list, pattern) do
    element_or_list |> all_cells() |> Enum.find(&String.contains?(&1.content, pattern))
  end

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

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "The Plaza"
      assert output =~ "Ashwell"
      assert output =~ "North Alley"
      assert output =~ "West Street"
      assert output =~ "East Street"
    end

    test "renders connected grid borders" do
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

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "┌"
      assert output =~ "┘"
      assert output =~ "┼"
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

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "Ashwell"
      assert output =~ "North Alley"
      assert output =~ "West Street"
      assert output =~ "The Plaza"
    end

    test "renders building name in grid cell" do
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

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "The Lame Horse"
      assert output =~ "╔"
      assert output =~ "╚"
    end

    test "highlights center building label and box when inside, leaves non-center white" do
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

      element = Surroundings.render(vicinity)

      white = Ratatouille.Constants.color(:white)
      highlight_color = Ratatouille.Constants.color(:cyan)

      plain_cell = find_cell(element, "The Plaza")
      assert plain_cell.color == white

      label_cell = find_cell(element, "The Lame Horse")
      assert label_cell.color == highlight_color

      box_cell = find_cell(element, "╔")
      assert box_cell.color == highlight_color
    end

    test "highlights only the center block, leaves all neighbours white" do
      # east_street at [1][1] (center); lame_horse at [0][1] (neighbour)
      vicinity = %Vicinity{
        id: "east_street",
        type: :street,
        people: [],
        neighbourhood: [
          [nil, "lame_horse", nil],
          [nil, "east_street", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      element = Surroundings.render(vicinity)

      white = Ratatouille.Constants.color(:white)
      highlight_color = Ratatouille.Constants.color(:cyan)

      plain_cell = find_cell(element, "East Street")
      assert plain_cell.color == highlight_color

      building_cell = find_cell(element, "The Lame Horse")
      assert building_cell.color == white
    end

    test "highlights label but not building box when standing at building exterior" do
      # lame_horse at [1][1] (center), player is outside (building_type set — not an interior block)
      vicinity = %Vicinity{
        id: "lame_horse",
        type: :inn,
        people: [],
        neighbourhood: [
          [nil, "east_street", nil],
          [nil, "lame_horse", nil],
          [nil, "south_alley", nil]
        ],
        building_type: :inn
      }

      element = Surroundings.render(vicinity)

      white = Ratatouille.Constants.color(:white)
      highlight_color = Ratatouille.Constants.color(:cyan)

      label_cell = find_cell(element, "The Lame Horse")
      assert label_cell.color == highlight_color

      box_cell = find_cell(element, "╔")
      assert box_cell.color == white
    end

    test "returns a label element when no neighbourhood" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: nil,
        building_type: nil
      }

      assert %Element{tag: :label} = Surroundings.render(vicinity)
    end
  end
end
