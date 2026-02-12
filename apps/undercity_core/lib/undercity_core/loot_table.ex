defmodule UndercityCore.LootTable do
  @moduledoc """
  Per-block-type loot tables for searching.

  A loot table is an ordered list of `{probability, item_name}` entries.
  Probabilities are cumulative: a roll is checked against each entry in order,
  accumulating chances until a match is found or the table is exhausted.
  """

  alias UndercityCore.Item

  @type entry :: {float(), String.t()}
  @type t :: [entry()]

  @tables %{
    square: [{0.20, "Chalk"}, {0.05, "Junk"}]
  }

  @default_table [{0.10, "Junk"}]

  @spec for_block_type(atom()) :: t()
  def for_block_type(type) do
    Map.get(@tables, type, @default_table)
  end

  @spec roll(t(), float()) :: {:found, Item.t()} | :nothing
  def roll(table, value \\ :rand.uniform()) do
    find_item(table, value, 0.0)
  end

  defp find_item([], _value, _acc), do: :nothing

  defp find_item([{chance, name} | rest], value, acc) do
    threshold = acc + chance

    if value < threshold do
      {:found, Item.new(name)}
    else
      find_item(rest, value, threshold)
    end
  end
end
