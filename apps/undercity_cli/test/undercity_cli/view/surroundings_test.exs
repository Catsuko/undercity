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
        id: "ashwarden_square",
        type: :square,
        people: [],
        neighbourhood: [
          ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
          ["aldermans_well", "ashwarden_square", "needle_lane"],
          ["broad_alley", "coin_street", "cut_passage"]
        ],
        building_type: nil
      }

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "Ashwarden Square"
      assert output =~ "Warden's Archive"
      assert output =~ "Alderman's Well"
      assert output =~ "Little Lane"
      assert output =~ "Broad Alley"
    end

    test "renders connected grid borders" do
      vicinity = %Vicinity{
        id: "ashwarden_square",
        type: :square,
        people: [],
        neighbourhood: [
          ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
          ["aldermans_well", "ashwarden_square", "needle_lane"],
          ["broad_alley", "coin_street", "cut_passage"]
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
        id: "wormgarden",
        type: :graveyard,
        people: [],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "wormgarden", "hollow_house"],
          [nil, "sextons_close", "sextons_row"]
        ],
        building_type: nil
      }

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "Wormgarden"
      assert output =~ "Hollow House"
      assert output =~ "Sexton's Close"
      assert output =~ "Sexton's Row"
    end

    test "renders inn block name in grid cell" do
      vicinity = %Vicinity{
        id: "coin_street",
        type: :street,
        people: [],
        neighbourhood: [
          ["ashwarden_square", "needle_lane", nil],
          ["coin_street", "cobweb_inn", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      output = vicinity |> Surroundings.render() |> all_text()

      assert output =~ "The Cobweb Inn"
    end

    test "highlights center block, leaves neighbours white" do
      vicinity = %Vicinity{
        id: "ashwarden_square",
        type: :square,
        people: [],
        neighbourhood: [
          ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
          ["aldermans_well", "ashwarden_square", "needle_lane"],
          ["broad_alley", "coin_street", "cut_passage"]
        ],
        building_type: nil
      }

      element = Surroundings.render(vicinity)

      white = Ratatouille.Constants.color(:white)
      highlight_color = Ratatouille.Constants.color(:cyan)

      center_cell = find_cell(element, "Ashwarden Square")
      assert center_cell.color == highlight_color

      plain_cell = find_cell(element, "Warden's Archive")
      assert plain_cell.color == white
    end

    test "highlights only the center block when surrounded by neighbours" do
      vicinity = %Vicinity{
        id: "coin_street",
        type: :street,
        people: [],
        neighbourhood: [
          [nil, "ashwarden_square", nil],
          [nil, "coin_street", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      element = Surroundings.render(vicinity)

      white = Ratatouille.Constants.color(:white)
      highlight_color = Ratatouille.Constants.color(:cyan)

      center_cell = find_cell(element, "Coin Street")
      assert center_cell.color == highlight_color

      neighbour_cell = find_cell(element, "Ashwarden Square")
      assert neighbour_cell.color == white
    end

    test "returns a label element when no neighbourhood" do
      vicinity = %Vicinity{
        id: "ashwarden_square",
        type: :square,
        people: [],
        neighbourhood: nil,
        building_type: nil
      }

      assert %Element{tag: :label} = Surroundings.render(vicinity)
    end
  end
end
