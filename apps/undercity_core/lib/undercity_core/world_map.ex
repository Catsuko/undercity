defmodule UndercityCore.WorldMap do
  @moduledoc """
  Static configuration for the undercity world.

  Defines the blocks that make up the world and their connections.
  """

  @spawn_block "plaza"

  def spawn_block, do: @spawn_block

  def blocks do
    [
      %{
        id: "ashwell",
        name: "Ashwell",
        description: "Dry stone fountain, water long gone.",
        exits: %{east: "north_alley", south: "west_street"}
      },
      %{
        id: "north_alley",
        name: "North Alley",
        description: "Narrow and watched by shuttered windows.",
        exits: %{west: "ashwell", east: "wormgarden", south: "plaza"}
      },
      %{
        id: "wormgarden",
        name: "Wormgarden",
        description: "Crooked headstones in black soil.",
        exits: %{west: "north_alley", south: "east_street"}
      },
      %{
        id: "west_street",
        name: "West Street",
        description: "Cobblestones caked in dust and filth.",
        exits: %{north: "ashwell", east: "plaza", south: "the_stray"}
      },
      %{
        id: "plaza",
        name: "The Plaza",
        description: "The central gathering place of the undercity.",
        exits: %{north: "north_alley", east: "east_street", south: "south_alley", west: "west_street"}
      },
      %{
        id: "east_street",
        name: "East Street",
        description: "Cracked flagstones lined with iron lamp posts.",
        exits: %{north: "wormgarden", west: "plaza", south: "lame_horse"}
      },
      %{
        id: "the_stray",
        name: "The Stray",
        description: "A dead end, rubble and broken carts.",
        exits: %{north: "west_street", east: "south_alley"}
      },
      %{
        id: "south_alley",
        name: "South Alley",
        description: "Low archway dripping with condensation.",
        exits: %{north: "plaza", west: "the_stray", east: "lame_horse"}
      },
      %{
        id: "lame_horse",
        name: "The Lame Horse Inn",
        description: "A sagging timber frame, the sign above the door barely legible.",
        exits: %{north: "east_street", west: "south_alley"}
      }
    ]
  end
end
