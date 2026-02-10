defmodule UndercityCore.Block do
  @moduledoc """
  A block is a location in the undercity where people can gather.
  """

  alias UndercityCore.Person

  @enforce_keys [:id, :name, :type]
  defstruct [:id, :name, :type, people: MapSet.new(), exits: %{}]

  @type direction :: :north | :south | :east | :west | :enter | :exit
  @type block_type :: :street | :square | :fountain | :graveyard | :space | :inn
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          type: block_type(),
          people: MapSet.t(Person.t()),
          exits: %{direction() => String.t()}
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

  @spec add_person(t(), Person.t()) :: t()
  def add_person(%__MODULE__{} = block, %Person{} = person) do
    %{block | people: MapSet.put(block.people, person)}
  end

  @spec remove_person(t(), Person.t()) :: t()
  def remove_person(%__MODULE__{} = block, %Person{} = person) do
    %{block | people: MapSet.delete(block.people, person)}
  end

  @spec find_person_by_name(t(), String.t()) :: Person.t() | nil
  def find_person_by_name(%__MODULE__{} = block, name) when is_binary(name) do
    Enum.find(block.people, fn person -> person.name == name end)
  end

  @spec list_people(t()) :: [Person.t()]
  def list_people(%__MODULE__{} = block) do
    MapSet.to_list(block.people)
  end
end
