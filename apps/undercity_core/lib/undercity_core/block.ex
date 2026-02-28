defmodule UndercityCore.Block do
  @moduledoc """
  A block is a location in the undercity where people can gather.
  """

  @enforce_keys [:id, :name, :type]
  defstruct [:id, :name, :type, :scribble, people: MapSet.new(), exits: %{}]

  @type direction :: :north | :south | :east | :west | :enter | :exit
  @type block_type :: UndercityCore.BlockType.t()
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          type: block_type(),
          people: MapSet.t(String.t()),
          exits: %{direction() => String.t()},
          scribble: String.t() | nil
        }

  @spec new(String.t(), String.t(), block_type(), %{direction() => String.t()}) :: t()
  def new(id, name, type, exits \\ %{}) do
    %__MODULE__{
      id: id,
      name: name,
      type: type,
      exits: exits
    }
  end

  @spec add_person(t(), String.t()) :: t()
  def add_person(%__MODULE__{} = block, player_id) when is_binary(player_id) do
    %{block | people: MapSet.put(block.people, player_id)}
  end

  @spec remove_person(t(), String.t()) :: t()
  def remove_person(%__MODULE__{} = block, player_id) when is_binary(player_id) do
    %{block | people: MapSet.delete(block.people, player_id)}
  end

  @spec has_person?(t(), String.t()) :: boolean()
  def has_person?(%__MODULE__{} = block, player_id) when is_binary(player_id) do
    MapSet.member?(block.people, player_id)
  end

  @spec list_people(t()) :: [String.t()]
  def list_people(%__MODULE__{} = block) do
    MapSet.to_list(block.people)
  end

  @spec scribble(t(), String.t()) :: t()
  def scribble(%__MODULE__{} = block, text) when is_binary(text) do
    %{block | scribble: text}
  end
end
