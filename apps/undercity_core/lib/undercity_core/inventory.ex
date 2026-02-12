defmodule UndercityCore.Inventory do
  @moduledoc """
  A bounded collection of items a player can carry.
  """

  alias UndercityCore.Item

  @max_size 5

  defstruct items: []

  @type t :: %__MODULE__{
          items: [Item.t()]
        }

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Adds an item to the inventory. Returns the inventory unchanged if full.
  """
  @spec add_item(t(), Item.t()) :: t()
  def add_item(%__MODULE__{items: items} = inventory, %Item{} = item) do
    if full?(inventory) do
      inventory
    else
      %{inventory | items: items ++ [item]}
    end
  end

  @spec list_items(t()) :: [Item.t()]
  def list_items(%__MODULE__{items: items}), do: items

  @spec full?(t()) :: boolean()
  def full?(%__MODULE__{items: items}), do: length(items) >= @max_size

  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{items: items}), do: length(items)
end
