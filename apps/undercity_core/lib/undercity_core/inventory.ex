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

  @doc """
  Returns a new empty inventory.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds an item to the inventory.

  - Returns `{:error, :full}` if the inventory is at capacity (15 items)
  """
  @spec add_item(t(), Item.t()) :: {:ok, t()} | {:error, :full}
  def add_item(%__MODULE__{items: items} = inventory, %Item{} = item) do
    if full?(inventory) do
      {:error, :full}
    else
      {:ok, %{inventory | items: items ++ [item]}}
    end
  end

  @doc """
  Returns the list of items in the inventory.
  """
  @spec list_items(t()) :: [Item.t()]
  def list_items(%__MODULE__{items: items}), do: items

  @doc """
  Returns true if the inventory is at maximum capacity (15 items).
  """
  @spec full?(t()) :: boolean()
  def full?(%__MODULE__{items: items}), do: length(items) >= @max_size

  @doc """
  Returns the number of items currently in the inventory.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{items: items}), do: length(items)

  @doc """
  Finds the first item in the inventory matching the given name.

  - Returns `{:ok, item, index}` with the item and its position
  - Returns `:not_found` if no item matches
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

  @doc """
  Finds the first item with the given atom id and consumes one use.

  - Returns `{:ok, updated_inventory}` on success, removing the item if its last use was spent
  - Returns `{:error, :item_missing}` if no item with the given id exists
  """
  @spec use_item(t(), atom()) :: {:ok, t()} | {:error, :item_missing}
  def use_item(%__MODULE__{items: items} = inventory, item_id) when is_atom(item_id) do
    case Enum.find_index(items, fn item -> item.id == item_id end) do
      nil ->
        {:error, :item_missing}

      index ->
        item = Enum.at(items, index)

        case Item.use(item) do
          :spent -> {:ok, remove_at(inventory, index)}
          {:ok, used} -> {:ok, replace_at(inventory, index, used)}
        end
    end
  end
end
