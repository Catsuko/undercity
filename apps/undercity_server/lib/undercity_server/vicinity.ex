defmodule UndercityServer.Vicinity do
  @moduledoc """
  Struct representing the player's immediate surroundings, centred on a single block.

  - Includes the central block's type, present players, neighbourhood grid, building type, and scribble
  - Use `build/1` to construct from live server state (queries `Block` and `Player.Store`)
  - Use `new/3` when assembling from known data, e.g. in tests
  """

  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.Player.Store, as: PlayerStore

  defstruct [:id, :type, :people, :neighbourhood, :building_type, :scribble]

  @doc """
  Builds a `Vicinity` for `block_id` by querying live server state.

  - Fetches present player IDs and scribble from `Block.info/1`
  - Resolves display names from `Player.Store.get_names/1`
  """
  def build(block_id) do
    {^block_id, player_ids, scribble} = Block.info(block_id)
    names = PlayerStore.get_names(player_ids)

    people =
      Enum.map(player_ids, fn id ->
        %{id: id, name: Map.get(names, id, "Unknown")}
      end)

    new(block_id, people, scribble: scribble)
  end

  @doc """
  Constructs a `Vicinity` centred on `block_id` with the given `people` list.

  - `people` is a list of `%{id: player_id, name: name}` maps.
  - Optional: `:scribble` keyword — the block's scribble text, defaults to `nil`.
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
  Returns the display name of the vicinity's central block.
  """
  def name(%__MODULE__{} = vicinity) do
    name_for(centre_id(vicinity))
  end

  @doc """
  Returns the display name for `block_id`, falling back to the block ID string if no name is configured.
  """
  def name_for(block_id) do
    WorldMap.block_name(block_id) || block_id
  end

  @doc """
  Returns `true` if the central block is inside a building, `false` otherwise.

  A block is considered inside when the central block has no building type but its parent (neighbourhood centre) does.
  """
  def inside?(%__MODULE__{} = vicinity) do
    centre = centre_id(vicinity)
    WorldMap.building_type(centre) != nil and vicinity.building_type == nil
  end

  @doc """
  Returns `true` if `block_id` is the root of a building (has a building type configured).
  """
  def building?(block_id) do
    WorldMap.building_type(block_id) != nil
  end

  defp centre_id(%__MODULE__{neighbourhood: nil}), do: nil

  defp centre_id(%__MODULE__{neighbourhood: neighbourhood}) do
    neighbourhood |> Enum.at(1) |> Enum.at(1)
  end
end
