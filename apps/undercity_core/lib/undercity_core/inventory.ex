defmodule UndercityCore.Inventory do
  @moduledoc """
  A bounded collection of items a player can carry.
  """

  alias UndercityCore.Item

  @max_size 15

  defstruct items: []

  @type t :: %__MODULE__{
          items: [Item.t()]
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds an item to the inventory. Returns `{:ok, inventory}` on success
  or `{:error, :full}` if the inventory is at capacity.
  """
  @spec add_item(t(), Item.t()) :: {:ok, t()} | {:error, :full}
  def add_item(%__MODULE__{items: items} = inventory, %Item{} = item) do
    if full?(inventory) do
      {:error, :full}
    else
      {:ok, %{inventory | items: items ++ [item]}}
    end
  end

  @spec list_items(t()) :: [Item.t()]
  def list_items(%__MODULE__{items: items}), do: items

  @spec full?(t()) :: boolean()
  def full?(%__MODULE__{items: items}), do: length(items) >= @max_size

  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{items: items}), do: length(items)

  @doc """
  Finds the first item matching the given name.
  Returns `{:ok, item, index}` or `:not_found`.
  """
  @spec find_item(t(), String.t()) :: {:ok, Item.t(), non_neg_integer()} | :not_found
  def find_item(%__MODULE__{items: items}, name) when is_binary(name) do
    case Enum.find_index(items, fn item -> item.name == name end) do
      nil -> :not_found
      index -> {:ok, Enum.at(items, index), index}
    end
  end

  @doc """
  Replaces the item at the given index.
  """
  @spec replace_at(t(), non_neg_integer(), Item.t()) :: t()
  def replace_at(%__MODULE__{items: items} = inventory, index, %Item{} = item) do
    %{inventory | items: List.replace_at(items, index, item)}
  end

  @doc """
  Removes the item at the given index.
  """
  @spec remove_at(t(), non_neg_integer()) :: t()
  def remove_at(%__MODULE__{items: items} = inventory, index) do
    %{inventory | items: List.delete_at(items, index)}
  end
end
