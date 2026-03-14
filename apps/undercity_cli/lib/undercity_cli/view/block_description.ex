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
    inn: "Low beams sag overhead in a room thick with the smell of damp wood and old smoke.",
    space_apothecary: "A low door set beneath a hanging bundle of dried roots, the paint above it flaked to nothing.",
    apothecary:
      "Crooked shelves line the walls, the floor scattered with broken glass and the dark stains of whatever was spilled.",
    space_archive: "A plain stone building with iron-banded shutters, its entrance half-blocked by a stack of crates.",
    archive: "Tall shelves press in from every side, the air thick with dust and the slow smell of decaying leather.",
    space_bazaar: "A low shopfront, its window boards warped and the colorful signage faded.",
    bazaar:
      "A cramped room behind a scarred wooden counter, upturned crates and loose wrapping scattered across the floor.",
    space_bell_tower: "A stone tower rises above the surrounding rooflines, its upper windows dark and long unlit.",
    bell_tower:
      "The steps spiral upward into cold dark. The bell above hangs still, its surface eaten through with rust.",
    space_blacksmith:
      "A wide doorway of heavy timber, the iron fittings above it dark with soot and the step worn deep by years of use.",
    blacksmith:
      "The forge sits dead in the corner, tools scattered where they fell. Piles of scrap and cinder heap against the walls.",
    space_church:
      "A building of fitted stone with a peaked roof and narrow lancet windows, its arched doorway worn smooth.",
    church: "A long cold room of bare stone, rows of rough benches facing a stripped altar at the far end.",
    space_dungeon: "A heavy iron door sits flush with the stone, a city watch mark scratched into the archway above it.",
    dungeon:
      "A descent of damp steps into a corridor of fitted stone. Iron-barred cells line either side, the far end lost in dark.",
    space_garrison:
      "A squat building of heavy stone with narrow windows, a ward lantern mounted cold above the entrance.",
    garrison: "A long room of bare stone with ranked benches and a weapons rack along the far wall.",
    space_guild: "A broad-fronted hall with dark timber framing, the guild's mark mounted above the door.",
    guild: "A wood-panelled room, its walls lined with various cabinets and a cold hearth set into one side.",
    space_manor: "A stone house built wider than its neighbours, its upper floors looming out over the street.",
    manor:
      "A wide entrance hall, a broad staircase at the far end and the remains of better furnishings along the walls.",
    space_storehouse: "A long, low building of heavy timber, its wide double doors set flush with the front wall.",
    storehouse: "A bare timber space, sacks and crates stacked in rough order along the walls.",
    space_tavern: "A hanging sign creaks above the door, its painted figure long since worn to a dark smear.",
    tavern:
      "Smoke-blackened beams, a floor of loose boards, and a long counter cluttered with abandoned cups and old rings from glasses.",
    space_townhouse:
      "A narrow building of dark brick, its shutters close to the street and a step worn hollow at the door.",
    townhouse: "A bare entrance hall giving onto a run of warped doors, the smell of close-lived-in air still present.",
    space_workshop: "A wide doorway of bare timber, the smell of sawdust and metal oil still faint in the air.",
    workshop: "Overturned benches and scattered shavings cover the floor, the tool hooks along the walls mostly bare."
  }

  @grid_color Ratatouille.Constants.color(:white)
  @highlight Ratatouille.Constants.color(:cyan)

  def render(%Vicinity{} = vicinity, current_player) do
    description = Map.fetch!(@descriptions, description_key(vicinity))
    prefix = block_prefix(vicinity)
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

  def scribble_surface(%Vicinity{} = v) do
    if v.type == :space or Vicinity.inside?(v), do: "on the wall", else: "on the ground"
  end

  defp description_key(%Vicinity{type: :space, building_type: bt}) when bt != nil, do: :"space_#{bt}"

  defp description_key(%Vicinity{type: type}), do: type

  defp block_prefix(%Vicinity{type: :space}), do: "outside"

  defp block_prefix(%Vicinity{} = v) do
    if Vicinity.inside?(v), do: "inside", else: "at"
  end
end
