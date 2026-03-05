defmodule UndercityCli.View.BlockDescription do
  @moduledoc """
  Renders the description of the current block including name, flavour text,
  scribbles, and people present.
  """

  import Ratatouille.View

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

  @grid_color Ratatouille.Constants.color(:white)
  @highlight Ratatouille.Constants.color(:cyan)

  def render(%Vicinity{} = vicinity, current_player) do
    description = Map.fetch!(@descriptions, description_key(vicinity))
    prefix = block_prefix(vicinity.type)
    name = Vicinity.name(vicinity)

    location_line =
      label do
        text(content: "You are #{prefix} ", color: @grid_color)
        text(content: name, color: @highlight)
        text(content: ". #{description}", color: @grid_color)
      end

    scribble_elements =
      case vicinity.scribble do
        nil ->
          []

        text ->
          surface = scribble_surface(vicinity)

          [
            label do
              text(content: "Someone has scribbled ", color: @grid_color)

              text(
                content: text,
                color: @grid_color,
                attributes: Ratatouille.Constants.attribute(:bold)
              )

              text(content: " #{surface}.", color: @grid_color)
            end
          ]
      end

    people_line = label(content: describe_people(vicinity.people, current_player), color: @grid_color)

    [location_line] ++ scribble_elements ++ [label(content: ""), people_line]
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
end
