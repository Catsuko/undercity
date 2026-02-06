defmodule UndercityCore.WorldMap do
  @moduledoc """
  Static configuration for the undercity world.

  Defines the blocks that make up the world and their connections.
  Connections are defined once as tuples and exits are derived
  automatically in both directions.
  """

  @spawn_block "plaza"

  @block_defs [
    %{id: "ashwell", name: "Ashwell", description: "Dry stone fountain, water long gone."},
    %{id: "north_alley", name: "North Alley", description: "Narrow and watched by shuttered windows."},
    %{id: "wormgarden", name: "Wormgarden", description: "Crooked headstones in black soil."},
    %{id: "west_street", name: "West Street", description: "Cobblestones caked in dust and filth."},
    %{id: "plaza", name: "The Plaza", description: "The central gathering place of the undercity."},
    %{id: "east_street", name: "East Street", description: "Cracked flagstones lined with iron lamp posts."},
    %{id: "the_stray", name: "The Stray", description: "A dead end, rubble and broken carts."},
    %{id: "south_alley", name: "South Alley", description: "Low archway dripping with condensation."},
    %{id: "lame_horse", name: "The Lame Horse Inn", description: "A sagging timber frame, the sign above the door barely legible."}
  ]

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

  def spawn_block, do: @spawn_block

  def blocks do
    exits = build_exits(@connections)

    Enum.map(@block_defs, fn block ->
      Map.put(block, :exits, Map.get(exits, block.id, %{}))
    end)
  end

  defp build_exits(connections) do
    Enum.reduce(connections, %{}, fn {from, direction, to}, acc ->
      reverse = reverse_direction(direction)

      acc
      |> Map.update(from, %{direction => to}, &Map.put(&1, direction, to))
      |> Map.update(to, %{reverse => from}, &Map.put(&1, reverse, from))
    end)
  end

  defp reverse_direction(:north), do: :south
  defp reverse_direction(:south), do: :north
  defp reverse_direction(:east), do: :west
  defp reverse_direction(:west), do: :east
end
