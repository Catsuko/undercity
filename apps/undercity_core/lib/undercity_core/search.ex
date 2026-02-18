defmodule UndercityCore.Search do
  @moduledoc """
  Search logic for finding items in the undercity.
  """

  alias UndercityCore.Item
  alias UndercityCore.LootTable

  @doc """
  Performs a search in a block of the given type.

  Returns `{:found, item}` if something is found, or `:nothing` otherwise.

  Accepts an optional random value (0.0..1.0) for testability.
  """
  @spec search(atom(), float()) :: {:found, Item.t()} | :nothing
  def search(block_type, roll \\ :rand.uniform()) do
    block_type |> LootTable.for_block_type() |> LootTable.roll(roll)
  end
end
