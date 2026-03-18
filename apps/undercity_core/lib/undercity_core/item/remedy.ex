defmodule UndercityCore.Item.Remedy do
  @moduledoc """
  Healing items and their effects.

  Maps catalogue atom ids to possible outcomes. Each entry is a list of
  equally-weighted effect tuples (e.g. `{:heal, 15}`).
  """

  alias UndercityCore.Item.Catalogue

  @table %{
    salve: [{:heal, 15}]
  }

  @table_by_name Map.new(@table, fn {id, outcomes} -> {Catalogue.name!(id), outcomes} end)

  @doc """
  Returns the effect of using the named remedy item, or `:not_a_remedy`.
  """
  @spec effect(String.t()) :: {:heal, pos_integer()} | :not_a_remedy
  def effect(item_name) when is_binary(item_name) do
    case Map.fetch(@table_by_name, item_name) do
      {:ok, outcomes} -> Enum.random(outcomes)
      :error -> :not_a_remedy
    end
  end

  @doc """
  Returns true if the named item is a remedy.
  """
  @spec remedy?(String.t()) :: boolean()
  def remedy?(item_name) when is_binary(item_name), do: Map.has_key?(@table_by_name, item_name)

  @doc """
  Returns the catalogue atom ids of all registered remedy items.
  """
  @spec all_ids() :: [atom()]
  def all_ids, do: Map.keys(@table)
end
