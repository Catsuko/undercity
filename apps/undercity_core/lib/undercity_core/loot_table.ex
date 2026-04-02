defmodule UndercityCore.LootTable do
  @moduledoc """
  Per-block-type loot tables for searching.

  - Each table is an ordered list of `{probability, item_id}` entries
  - `item_id` is a canonical atom from `UndercityCore.Item.Catalogue`
  - Probabilities are cumulative: a roll checks each entry in order until a match or exhaustion
  """

  alias UndercityCore.Item

  @type item_spec :: atom()
  @type entry :: {float(), item_spec()}
  @type t :: [entry()]

  @tables %{
    square: [{0.20, :chalk}, {0.05, :junk}, {0.05, :iron_pipe}],
    street: [{0.08, :iron_pipe}, {0.10, :junk}],
    graveyard: [{0.20, :mushroom}],
    inn: [{0.40, :iron_pipe}],
    apothecary: [{0.25, :salve}],
    church: [{0.10, :salve}],
    bazaar: [{0.10, :salve}, {0.10, :junk}]
  }

  @default_table [{0.10, :junk}]

  @doc """
  Returns the loot table for the given block type atom.

  - Falls back to the default table (`[{0.10, :junk}]`) if no specific table exists
  """
  @spec for_block_type(atom()) :: t()
  def for_block_type(type) do
    Map.get(@tables, type, @default_table)
  end

  @doc "Returns the atom ids of all block types with explicit loot tables."
  @spec all_block_types() :: [atom()]
  def all_block_types, do: Map.keys(@tables)

  @doc """
  Rolls against a loot table, returning a found item or nothing.

  - `value` is a float 0.0–1.0; defaults to `:rand.uniform/0` for testability
  - Returns `{:found, item}` or `:nothing`
  """
  @spec roll(t(), float()) :: {:found, Item.t()} | :nothing
  def roll(table, value \\ :rand.uniform()) do
    find_item(table, value, 0.0)
  end

  defp find_item([], _value, _acc), do: :nothing

  defp find_item([{chance, spec} | rest], value, acc) do
    threshold = acc + chance

    if value < threshold do
      {:found, Item.build(spec)}
    else
      find_item(rest, value, threshold)
    end
  end
end
