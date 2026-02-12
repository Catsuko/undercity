defmodule UndercityCore.Search do
  @moduledoc """
  Search logic for finding items in the undercity.
  """

  alias UndercityCore.Inventory
  alias UndercityCore.Item

  @find_chance 0.1

  @doc """
  Performs a search with a chance to find an item.

  Returns `{:found, item, updated_inventory}` if something is found and
  the inventory has space, or `:nothing` otherwise.

  Accepts an optional random value (0.0..1.0) for testability.
  """
  @spec search(Inventory.t(), float()) :: {:found, Item.t(), Inventory.t()} | :nothing
  def search(%Inventory{} = inventory, roll \\ :rand.uniform()) do
    if roll < @find_chance do
      item = Item.new("Junk")

      if Inventory.full?(inventory) do
        :nothing
      else
        {:found, item, Inventory.add_item(inventory, item)}
      end
    else
      :nothing
    end
  end
end
