defmodule UndercityCore.LootTable do
  @moduledoc """
  Per-block-type loot tables for searching.

  A loot table is an ordered list of `{probability, item_id}` entries,
  where `item_id` is a canonical atom from `UndercityCore.Item.Catalogue`.
  Probabilities are cumulative: a roll is checked against each entry in order,
  accumulating chances until a match is found or the table is exhausted.
  """

  alias UndercityCore.Item
  alias UndercityCore.Item.Catalogue

  @type item_spec :: atom()
  @type entry :: {float(), item_spec()}
  @type t :: [entry()]

  @tables %{
    square: [{0.20, :chalk}, {0.05, :junk}, {0.05, :iron_pipe}],
    street: [{0.08, :iron_pipe}, {0.10, :junk}],
    graveyard: [{0.20, :mushroom}],
    inn: [{0.40, :iron_pipe}]
  }

  @default_table [{0.10, :junk}]

  @spec for_block_type(atom()) :: t()
  def for_block_type(type) do
    Map.get(@tables, type, @default_table)
  end

  @doc "Returns the atom ids of all block types with explicit loot tables."
  @spec all_block_types() :: [atom()]
  def all_block_types, do: Map.keys(@tables)

  @spec roll(t(), float()) :: {:found, Item.t()} | :nothing
  def roll(table, value \\ :rand.uniform()) do
    find_item(table, value, 0.0)
  end

  defp find_item([], _value, _acc), do: :nothing

  defp find_item([{chance, spec} | rest], value, acc) do
    threshold = acc + chance

    if value < threshold do
      {:found, build_item(spec)}
    else
      find_item(rest, value, threshold)
    end
  end

  defp build_item(id) when is_atom(id) do
    {:ok, entry} = Catalogue.fetch(id)

    case entry.default_uses do
      nil -> Item.new(entry.name)
      uses -> Item.new(entry.name, uses)
    end
  end
end
