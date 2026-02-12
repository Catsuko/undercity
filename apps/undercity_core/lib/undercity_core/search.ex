defmodule UndercityCore.Search do
  @moduledoc """
  Search logic for finding items in the undercity.
  """

  alias UndercityCore.Item
  alias UndercityCore.LootTable

  @doc """
  Performs a search against a loot table.

  Returns `{:found, item}` if something is found, or `:nothing` otherwise.

  Accepts an optional random value (0.0..1.0) for testability.
  """
  @spec search(LootTable.t(), float()) :: {:found, Item.t()} | :nothing
  def search(loot_table, roll \\ :rand.uniform()) do
    LootTable.roll(loot_table, roll)
  end
end
