defmodule UndercityServer.Vicinity do
  @moduledoc """
  A limited window of the world surrounding a central block.

  Represents what the player perceives from where they stand — the
  block they occupy and the blocks around it. Moves with the player
  as they travel through the world.
  """

  alias UndercityCore.WorldMap

  defstruct [:id, :type, :people, :neighbourhood, :building_type, :scribble]

  @doc """
  Returns a new vicinity centred on the given block.
  """
  def new(block_id, people, opts \\ []) do
    %__MODULE__{
      id: block_id,
      type: WorldMap.block_type(block_id),
      people: people,
      neighbourhood: WorldMap.surrounding(block_id),
      building_type: WorldMap.building_type(block_id),
      scribble: Keyword.get(opts, :scribble)
    }
  end

  @doc """
  Returns the name of the vicinity's central block.
  """
  def name(%__MODULE__{} = vicinity) do
    name_for(centre_id(vicinity))
  end

  @doc """
  Returns the name of a given block.
  """
  def name_for(block_id) do
    base = WorldMap.block_name(block_id) || block_id

    case WorldMap.building_type(block_id) do
      nil -> base
      bt -> "#{base} #{bt |> Atom.to_string() |> String.capitalize()}"
    end
  end

  @doc """
  Returns true if the player is inside a building.
  """
  def inside?(%__MODULE__{} = vicinity) do
    centre = centre_id(vicinity)
    WorldMap.building_type(centre) != nil and vicinity.building_type == nil
  end

  @doc """
  Indicates if the given block is a building.
  """
  def building?(block_id) do
    WorldMap.building_type(block_id) != nil
  end

  defp centre_id(%__MODULE__{neighbourhood: nil}), do: nil

  defp centre_id(%__MODULE__{neighbourhood: neighbourhood}) do
    neighbourhood |> Enum.at(1) |> Enum.at(1)
  end
end
