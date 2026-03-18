defmodule UndercityCore.Item.Food do
  @moduledoc """
  Edible items and their effects.

  Maps catalogue atom ids to possible outcomes. Each entry is a list of
  equally-weighted effect tuples (e.g. `{:heal, 5}`, `{:damage, 5}`).
  """

  alias UndercityCore.Item.Catalogue

  @table %{
    mushroom: [{:heal, 5}, {:damage, 5}]
  }

  @table_by_name Map.new(@table, fn {id, outcomes} -> {Catalogue.name!(id), outcomes} end)

  @doc """
  Returns the effect of eating the named item, or `:not_edible`.
  """
  @spec effect(String.t()) :: {:heal, pos_integer()} | {:damage, pos_integer()} | :not_edible
  def effect(item_name) when is_binary(item_name) do
    case Map.fetch(@table_by_name, item_name) do
      {:ok, outcomes} -> Enum.random(outcomes)
      :error -> :not_edible
    end
  end

  @doc """
  Returns true if the named item is edible.
  """
  @spec edible?(String.t()) :: boolean()
  def edible?(item_name) when is_binary(item_name), do: Map.has_key?(@table_by_name, item_name)

  @doc """
  Returns the catalogue atom ids of all registered edible items.
  """
  @spec all_ids() :: [atom()]
  def all_ids, do: Map.keys(@table)
end
