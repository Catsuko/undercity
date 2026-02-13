defmodule UndercityServer.Vicinity do
  @moduledoc """
  A limited window of the world surrounding a central block.

  Represents what the player perceives from where they stand — the
  block they occupy and the blocks around it. Moves with the player
  as they travel through the world.

  Use `build/1` to construct a vicinity from live server state (fetches
  block info, player names, and scribble). Use `new/3` directly when
  assembling from known data (e.g. in tests).
  """

  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.Player.Store, as: PlayerStore

  defstruct [:id, :type, :people, :neighbourhood, :building_type, :scribble]

  @doc """
  Builds a vicinity by fetching block info, player names, and scribble
  from the running server processes.
  """
  def build(block_id) do
    {^block_id, player_ids} = Block.info(block_id)
    names = PlayerStore.get_names(player_ids)
    scribble = Block.get_scribble(block_id)

    people =
      Enum.map(player_ids, fn id ->
        %{id: id, name: Map.get(names, id, "Unknown")}
      end)

    new(block_id, people, scribble: scribble)
  end

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
