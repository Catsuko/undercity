defmodule UndercityCore.Block do
  @moduledoc """
  A block is a location in the undercity where people can gather.
  """

  alias UndercityCore.Person

  @enforce_keys [:id, :name]
  defstruct [:id, :name, :description, people: MapSet.new(), exits: %{}]

  @type direction :: :north | :south | :east | :west
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          people: MapSet.t(Person.t()),
          exits: %{direction() => String.t()}
        }

  @spec new(String.t(), String.t(), String.t() | nil, %{direction() => String.t()}) :: t()
  def new(id, name, description \\ nil, exits \\ %{}) do
    %__MODULE__{
      id: id,
      name: name,
      description: description,
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

  @spec exit(t(), direction()) :: {:ok, String.t()} | :error
  def exit(%__MODULE__{} = block, direction) do
    Map.fetch(block.exits, direction)
  end

  @spec list_exits(t()) :: [{direction(), String.t()}]
  def list_exits(%__MODULE__{} = block) do
    Map.to_list(block.exits)
  end

  @spec list_people(t()) :: [Person.t()]
  def list_people(%__MODULE__{} = block) do
    MapSet.to_list(block.people)
  end
end
