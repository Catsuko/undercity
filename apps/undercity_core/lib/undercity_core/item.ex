defmodule UndercityCore.Item do
  @moduledoc """
  An item that can be found and carried in the undercity.
  """

  alias UndercityCore.Item.Catalogue

  @enforce_keys [:name]
  defstruct [:id, :name, :uses]

  @type t :: %__MODULE__{
          id: atom() | nil,
          name: String.t(),
          uses: non_neg_integer() | nil
        }

  @doc """
  Creates a non-consumable item with the given name.
  """
  @spec new(String.t()) :: t()
  def new(name) when is_binary(name) do
    %__MODULE__{name: name}
  end

  @doc """
  Creates a consumable item with the given name and number of uses.
  """
  @spec new(String.t(), non_neg_integer()) :: t()
  def new(name, uses) when is_binary(name) and is_integer(uses) and uses > 0 do
    %__MODULE__{name: name, uses: uses}
  end

  @doc """
  Builds an `Item` from the given catalogue id.

  - `uses` overrides the catalogue default use count when provided.
  - Raises if `id` is not in the catalogue.
  """
  @spec build(atom()) :: t()
  @spec build(atom(), pos_integer() | nil) :: t()
  def build(id, uses \\ nil) when is_atom(id) do
    {:ok, entry} = Catalogue.fetch(id)
    %__MODULE__{id: id, name: entry.name, uses: uses || entry.default_uses}
  end

  @doc """
  Decrements the uses of a consumable item.
  Returns `{:ok, item}` with decremented uses, or `:spent` when uses reach 0.
  Items with `nil` uses are non-consumable and always return `{:ok, item}`.
  """
  @spec use(t()) :: {:ok, t()} | :spent
  def use(%__MODULE__{uses: nil} = item), do: {:ok, item}
  def use(%__MODULE__{uses: 1}), do: :spent
  def use(%__MODULE__{uses: uses} = item) when uses > 1, do: {:ok, %{item | uses: uses - 1}}
end
