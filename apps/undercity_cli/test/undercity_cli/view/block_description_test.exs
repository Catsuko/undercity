defmodule UndercityCli.View.BlockDescriptionTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.BlockDescription
  alias UndercityServer.Vicinity

  defp all_elements(%Ratatouille.Renderer.Element{} = el) do
    [el | Enum.flat_map(el.children, &all_elements/1)]
  end

  defp all_text(elements) when is_list(elements) do
    elements
    |> Enum.flat_map(&all_elements/1)
    |> Enum.map_join("", &Map.get(&1.attributes, :content, ""))
  end

  defp find_element_by_content(elements, content) when is_list(elements) do
    elements
    |> Enum.flat_map(&all_elements/1)
    |> Enum.find(&(Map.get(&1.attributes, :content) == content))
  end

  describe "render/2" do
    test "includes name, type-driven description, and people" do
      vicinity = %Vicinity{
        id: "ashwarden_square",
        type: :square,
        people: [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}],
        neighbourhood: [
          ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
          ["aldermans_well", "ashwarden_square", "needle_lane"],
          ["broad_alley", "coin_street", "cut_passage"]
        ],
        building_type: nil
      }

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "You are at"
      assert output =~ "Ashwarden Square"
      assert output =~ "A wide, open space where the ground has been worn flat by countless feet."
      assert output =~ "Mordecai"
      refute output =~ "Grimshaw"
    end

    test "does not include the neighbourhood grid" do
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

      elements = BlockDescription.render(vicinity, "Grimshaw")

      assert Enum.all?(elements, &match?(%{tag: :label}, &1))
    end

    test "shows alone message when only current player is present" do
      vicinity = %Vicinity{
        id: "aldermans_well",
        type: :fountain,
        people: [%{id: "1", name: "Grimshaw"}],
        neighbourhood: [
          [nil, nil, nil],
          [nil, "aldermans_well", "ashwarden_square"],
          [nil, "broad_alley", "coin_street"]
        ],
        building_type: nil
      }

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "You are at"
      assert output =~ "Alderman's Well"
      assert output =~ "A stone basin sits at the centre of this space, dry and cracked."
      assert output =~ "You are alone here."
    end

    test "uses 'outside' prefix with building-type description for space blocks" do
      vicinity = %Vicinity{
        id: "cobweb_inn",
        type: :space,
        people: [],
        neighbourhood: [
          ["ashwarden_square", "needle_lane", nil],
          ["coin_street", "cobweb_inn", nil],
          [nil, nil, nil]
        ],
        building_type: :inn
      }

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "You are outside"
      assert output =~ "The Cobweb Inn"
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

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "A patch of open ground"
    end

    test "renders scribble when present" do
      vicinity = %Vicinity{
        id: "ashwarden_square",
        type: :square,
        people: [],
        neighbourhood: [
          ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
          ["aldermans_well", "ashwarden_square", "needle_lane"],
          ["broad_alley", "coin_street", "cut_passage"]
        ],
        building_type: nil,
        scribble: "beware the dark"
      }

      elements = BlockDescription.render(vicinity, "Grimshaw")
      output = all_text(elements)

      assert output =~ "Someone has scribbled"
      assert output =~ "beware the dark"
      assert output =~ "on the ground."

      scribble_el = find_element_by_content(elements, "beware the dark")
      assert scribble_el.attributes.attributes == Ratatouille.Constants.attribute(:bold)
    end

    test "does not render scribble line when nil" do
      vicinity = %Vicinity{
        id: "ashwarden_square",
        type: :square,
        people: [],
        neighbourhood: [
          ["church_of_the_hollow_saint", "wardens_archive", "little_lane"],
          ["aldermans_well", "ashwarden_square", "needle_lane"],
          ["broad_alley", "coin_street", "cut_passage"]
        ],
        building_type: nil,
        scribble: nil
      }

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

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

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "rest in peace"
      assert output =~ "on a tombstone."
    end

    test "scribble says 'on the wall' for space with building" do
      vicinity = %Vicinity{
        id: "cobweb_inn",
        type: :space,
        people: [],
        neighbourhood: [
          ["ashwarden_square", "needle_lane", nil],
          ["coin_street", "cobweb_inn", nil],
          [nil, nil, nil]
        ],
        building_type: :inn,
        scribble: "enter here"
      }

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "enter here"
      assert output =~ "on the wall."
    end

    test "uses 'inside' prefix for inn blocks" do
      vicinity = %Vicinity{
        id: "cobweb_inn_interior",
        type: :inn,
        people: [],
        neighbourhood: [
          ["ashwarden_square", "needle_lane", nil],
          ["coin_street", "cobweb_inn", nil],
          [nil, nil, nil]
        ],
        building_type: nil
      }

      output = vicinity |> BlockDescription.render("Grimshaw") |> all_text()

      assert output =~ "You are inside"
      assert output =~ "The Cobweb Inn"
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
