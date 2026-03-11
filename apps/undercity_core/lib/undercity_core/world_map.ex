defmodule UndercityCore.WorldMap do
  @moduledoc """
  Static configuration for the undercity world.

  Defines the blocks that make up the world and their connections.
  Connections are defined once as tuples and exits are derived
  automatically in both directions.
  """

  @spawn_block "plaza"

  @block_defs [
    # Row 0
    %{id: "wardhouse", name: "Wardhouse", type: :space},
    %{id: "fellside", name: "Fellside", type: :street},
    %{id: "ashgate_tollbooth", name: "Ashgate Tollbooth", type: :space},
    %{id: "the_narrows", name: "The Narrows", type: :street},
    %{id: "ashworks", name: "Ashworks", type: :space},
    # Row 1
    %{id: "bleachfield", name: "Bleachfield", type: :space},
    %{id: "ashwell", name: "Ashwell", type: :fountain},
    %{id: "north_alley", name: "North Alley", type: :street},
    %{id: "wormgarden", name: "Wormgarden", type: :graveyard},
    %{id: "saltbone", name: "Saltbone", type: :space},
    # Row 2
    %{id: "quietside", name: "Quietside", type: :street},
    %{id: "west_street", name: "West Street", type: :street},
    %{id: "plaza", name: "The Plaza", type: :square},
    %{id: "east_street", name: "East Street", type: :street},
    %{id: "ashgate_cistern", name: "Ashgate Cistern", type: :space},
    # Row 3
    %{id: "sluice_gate", name: "Sluice Gate", type: :fountain},
    %{id: "the_stray", name: "The Stray", type: :street},
    %{id: "south_alley", name: "South Alley", type: :street},
    %{id: "lame_horse", name: "The Lame Horse", type: :space},
    %{id: "bonehouse", name: "Bonehouse", type: :space},
    # Row 4
    %{id: "mudgate", name: "Mudgate", type: :street},
    %{id: "shambles", name: "Shambles", type: :street},
    %{id: "charnel_cross", name: "Charnel Cross", type: :square},
    %{id: "crosswarden", name: "Crosswarden", type: :space},
    %{id: "the_breach", name: "The Breach", type: :street},
    # Interiors
    %{id: "lame_horse_interior", name: "The Lame Horse Inn", type: :inn},
    %{id: "saltbone_interior", name: "Saltbone Inn", type: :inn}
  ]

  @grid [
    ["wardhouse", "fellside", "ashgate_tollbooth", "the_narrows", "ashworks"],
    ["bleachfield", "ashwell", "north_alley", "wormgarden", "saltbone"],
    ["quietside", "west_street", "plaza", "east_street", "ashgate_cistern"],
    ["sluice_gate", "the_stray", "south_alley", "lame_horse", "bonehouse"],
    ["mudgate", "shambles", "charnel_cross", "crosswarden", "the_breach"]
  ]

  @grid_rows length(@grid)
  @grid_cols @grid |> hd() |> length()

  @grid_positions (for {row, r} <- Enum.with_index(@grid),
                       {id, c} <- Enum.with_index(row),
                       into: %{} do
                     {id, {r, c}}
                   end)

  @block_names (for %{id: id, name: name} <- @block_defs, into: %{} do
                  {id, name}
                end)

  @block_types (for %{id: id, type: type} <- @block_defs, into: %{} do
                  {id, type}
                end)

  @connections [
    # Existing 3×3 connections (unchanged)
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
    {"south_alley", :east, "lame_horse"},
    {"lame_horse", :enter, "lame_horse_interior"},
    # Row 0 (east-west)
    {"wardhouse", :east, "fellside"},
    {"fellside", :east, "ashgate_tollbooth"},
    {"ashgate_tollbooth", :east, "the_narrows"},
    {"the_narrows", :east, "ashworks"},
    # Col 0 (north-south)
    {"wardhouse", :south, "bleachfield"},
    {"bleachfield", :south, "quietside"},
    {"quietside", :south, "sluice_gate"},
    {"sluice_gate", :south, "mudgate"},
    # Col 4 (north-south)
    {"ashworks", :south, "saltbone"},
    {"saltbone", :south, "ashgate_cistern"},
    {"ashgate_cistern", :south, "bonehouse"},
    {"bonehouse", :south, "the_breach"},
    # Row 4 (east-west)
    {"mudgate", :east, "shambles"},
    {"shambles", :east, "charnel_cross"},
    {"charnel_cross", :east, "crosswarden"},
    {"crosswarden", :east, "the_breach"},
    # New outer to existing inner (north-south)
    {"fellside", :south, "ashwell"},
    {"ashgate_tollbooth", :south, "north_alley"},
    {"the_narrows", :south, "wormgarden"},
    # New outer to existing inner (east-west)
    {"bleachfield", :east, "ashwell"},
    {"quietside", :east, "west_street"},
    {"sluice_gate", :east, "the_stray"},
    {"wormgarden", :east, "saltbone"},
    {"east_street", :east, "ashgate_cistern"},
    {"lame_horse", :east, "bonehouse"},
    {"shambles", :north, "the_stray"},
    {"charnel_cross", :north, "south_alley"},
    {"crosswarden", :north, "lame_horse"},
    # Saltbone interior
    {"saltbone", :enter, "saltbone_interior"}
  ]

  @exits Enum.reduce(@connections, %{}, fn {from, direction, to}, acc ->
           reverse =
             case direction do
               :north -> :south
               :south -> :north
               :east -> :west
               :west -> :east
               :enter -> :exit
               :exit -> :enter
             end

           acc
           |> Map.update(from, %{direction => to}, &Map.put(&1, direction, to))
           |> Map.update(to, %{reverse => from}, &Map.put(&1, reverse, from))
         end)

  def spawn_block, do: @spawn_block

  defp neighbourhood(block_id) do
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

  defp grid_cell(r, c) when r >= 0 and r < @grid_rows and c >= 0 and c < @grid_cols do
    @grid |> Enum.at(r) |> Enum.at(c)
  end

  defp grid_cell(_r, _c), do: nil

  def block_name(block_id), do: Map.get(@block_names, block_id)

  def block_type(block_id), do: Map.get(@block_types, block_id)

  def resolve_exit(block_id, direction) do
    case get_in(@exits, [block_id, direction]) do
      nil -> :error
      destination_id -> {:ok, destination_id}
    end
  end

  def building_type(block_id) do
    case get_in(@exits, [block_id, :enter]) do
      nil -> nil
      interior_id -> Map.fetch!(@block_types, interior_id)
    end
  end

  defp parent_block(block_id) do
    case get_in(@exits, [block_id, :exit]) do
      nil -> :error
      parent_id -> {:ok, parent_id}
    end
  end

  @doc """
  Returns the ids of blocks surrounding the given block id.

  Grid blocks get their own neighbourhood directly. Interior blocks inherit
  their parent building's neighbourhood.
  """
  @spec surrounding(String.t(), pos_integer()) :: [[String.t() | nil]] | nil
  def surrounding(block_id, _distance \\ 3) do
    if Map.has_key?(@grid_positions, block_id) do
      {:ok, grid} = neighbourhood(block_id)
      grid
    else
      case parent_block(block_id) do
        {:ok, parent_id} ->
          {:ok, grid} = neighbourhood(parent_id)
          grid

        :error ->
          nil
      end
    end
  end

  def blocks do
    Enum.map(@block_defs, fn block ->
      Map.put(block, :exits, Map.get(@exits, block.id, %{}))
    end)
  end
end
