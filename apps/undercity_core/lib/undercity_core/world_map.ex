defmodule UndercityCore.WorldMap do
  @moduledoc """
  Static configuration for the undercity world.

  Defines the blocks that make up the world and their connections.
  Connections are defined once as tuples and exits are derived
  automatically in both directions.
  """

  @spawn_block "plaza"

  @block_defs [
    %{
      id: "ashwell",
      name: "Ashwell",
      description:
        "A dry stone well ringed by crumbling steps. Whatever water it once held is long gone, replaced by ash and offerings no one claims."
    },
    %{
      id: "north_alley",
      name: "North Alley",
      description: "A narrow passage between leaning walls, watched by shuttered windows that never quite stay closed."
    },
    %{
      id: "wormgarden",
      name: "Wormgarden",
      description:
        "A sunken burial ground where crooked headstones list in black soil. The names have worn away but the ground stays freshly turned."
    },
    %{
      id: "west_street",
      name: "West Street",
      description:
        "A crooked, winding street paved with cobblestones caked in dust and filth. The gutters run with something darker than rainwater."
    },
    %{
      id: "plaza",
      name: "The Plaza",
      description:
        "A wide, open gathering place beneath a dead grey sky. Faded banners hang in tatters from the walls, their colours long since bled away."
    },
    %{
      id: "east_street",
      name: "East Street",
      description:
        "A broad street where the flagstones have buckled and split. Rusted iron lamp posts lean at wrong angles, their bases swallowed by creeping black moss."
    },
    %{
      id: "the_stray",
      name: "The Stray",
      description:
        "A collapsed passage choked with rubble and broken carts. Whatever road this was, it leads nowhere now."
    },
    %{
      id: "south_alley",
      name: "South Alley",
      description:
        "A low, arched tunnel that reeks of damp and rot. Something has scratched long grooves into the stone walls."
    },
    %{
      id: "lame_horse",
      name: "The Lame Horse Inn",
      description:
        "A sagging timber-framed tavern with a sign above the door barely legible beneath the grime. The smell of stale ale seeps through the walls."
    }
  ]

  @grid [
    ["ashwell", "north_alley", "wormgarden"],
    ["west_street", "plaza", "east_street"],
    ["the_stray", "south_alley", "lame_horse"]
  ]

  @grid_positions (for {row, r} <- Enum.with_index(@grid),
                       {id, c} <- Enum.with_index(row),
                       into: %{} do
                     {id, {r, c}}
                   end)

  @block_names (for %{id: id, name: name} <- @block_defs, into: %{} do
                  {id, name}
                end)

  @connections [
    {"ashwell", :east, "north_alley"},
    {"ashwell", :south, "west_street"},
    {"north_alley", :east, "wormgarden"},
    {"north_alley", :south, "plaza"},
    {"west_street", :east, "plaza"},
    {"west_street", :south, "the_stray"},
    {"plaza", :east, "east_street"},
    {"plaza", :south, "south_alley"},
    {"wormgarden", :south, "east_street"},
    {"east_street", :south, "lame_horse"},
    {"the_stray", :east, "south_alley"},
    {"south_alley", :east, "lame_horse"}
  ]

  @exits Enum.reduce(@connections, %{}, fn {from, direction, to}, acc ->
           reverse =
             case direction do
               :north -> :south
               :south -> :north
               :east -> :west
               :west -> :east
             end

           acc
           |> Map.update(from, %{direction => to}, &Map.put(&1, direction, to))
           |> Map.update(to, %{reverse => from}, &Map.put(&1, reverse, from))
         end)

  def spawn_block, do: @spawn_block

  def neighbourhood(block_id) do
    case Map.fetch(@grid_positions, block_id) do
      {:ok, position} -> {:ok, build_neighbourhood(position)}
      :error -> :error
    end
  end

  defp build_neighbourhood({row, col}) do
    for dr <- -1..1 do
      Enum.map(-1..1, fn dc -> grid_cell(row + dr, col + dc) end)
    end
  end

  defp grid_cell(r, c) when r >= 0 and r < 3 and c >= 0 and c < 3 do
    id = @grid |> Enum.at(r) |> Enum.at(c)
    Map.fetch!(@block_names, id)
  end

  defp grid_cell(_r, _c), do: nil

  def resolve_exit(block_id, direction) do
    case get_in(@exits, [block_id, direction]) do
      nil -> :error
      destination_id -> {:ok, destination_id}
    end
  end

  def blocks do
    Enum.map(@block_defs, fn block ->
      Map.put(block, :exits, Map.get(@exits, block.id, %{}))
    end)
  end
end
