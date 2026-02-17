defmodule UndercityCli.View.BlockDescription do
  @moduledoc """
  Renders the description of the current block including name, flavour text,
  scribbles, and people present.
  """

  alias UndercityServer.Vicinity

  @descriptions %{
    street: "A narrow passage of broken cobblestones winding between crumbling walls.",
    square: "A wide, open space where the ground has been worn flat by countless feet.",
    fountain: "A stone basin sits at the centre of this space, dry and cracked.",
    graveyard: "Crooked headstones lean in black soil, their inscriptions worn smooth.",
    space: "A patch of open ground before a squat building, its timbers warped and dark.",
    space_inn: "A crooked timber frame leans over the street, its shuttered windows half-rotted from the damp.",
    inn: "Low beams sag overhead in a room thick with the smell of damp wood and old smoke."
  }

  @grid_color IO.ANSI.color(245)
  @highlight IO.ANSI.color(103)

  def render(%Vicinity{} = vicinity, current_player) do
    description = Map.fetch!(@descriptions, description_key(vicinity))
    prefix = block_prefix(vicinity.type)
    name = Vicinity.name(vicinity)

    sections = [
      Owl.Data.tag(
        ["You are #{prefix} ", Owl.Data.tag(name, @highlight), ". ", description],
        @grid_color
      )
    ]

    sections =
      sections ++
        case vicinity.scribble do
          nil ->
            []

          text ->
            surface = scribble_surface(vicinity)

            [
              Owl.Data.tag(
                ["Someone has scribbled ", Owl.Data.tag(text, :italic), " #{surface}."],
                @grid_color
              )
            ]
        end

    sections = sections ++ ["", describe_people(vicinity.people, current_player), ""]

    sections |> Enum.map_join("\n", &to_owl_string/1) |> IO.puts()
  end

  def describe_people(people, current_player) do
    others = Enum.reject(people, fn p -> p.name == current_player end)

    case others do
      [] -> "You are alone here."
      people -> "Present: #{Enum.map_join(people, ", ", & &1.name)}"
    end
  end

  def scribble_surface(%Vicinity{type: :graveyard}), do: "on a tombstone"
  def scribble_surface(%Vicinity{type: :inn}), do: "on the wall"
  def scribble_surface(%Vicinity{type: :space, building_type: bt}) when bt != nil, do: "on the wall"
  def scribble_surface(%Vicinity{}), do: "on the ground"

  defp description_key(%Vicinity{type: :space, building_type: bt}) when bt != nil, do: :"space_#{bt}"
  defp description_key(%Vicinity{type: type}), do: type

  defp block_prefix(:space), do: "outside"
  defp block_prefix(:inn), do: "inside"
  defp block_prefix(_type), do: "at"

  defp to_owl_string(data), do: data |> Owl.Data.to_chardata() |> IO.iodata_to_binary()
end
