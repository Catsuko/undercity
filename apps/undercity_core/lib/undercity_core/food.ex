defmodule UndercityCore.Food do
  @moduledoc """
  Edible items and their effects.

  Maps item names to possible outcomes. Each entry is a list of
  equally-weighted effect tuples (e.g. `{:heal, 5}`, `{:damage, 5}`).
  """

  @table %{
    "Mushroom" => [{:heal, 5}, {:damage, 5}]
  }

  @doc """
  Returns the effect of eating the named item, or `:not_edible`.
  """
  @spec effect(String.t()) :: {:heal, pos_integer()} | {:damage, pos_integer()} | :not_edible
  def effect(item_name) do
    case Map.fetch(@table, item_name) do
      {:ok, outcomes} -> Enum.random(outcomes)
      :error -> :not_edible
    end
  end

  @doc """
  Returns true if the named item is edible.
  """
  @spec edible?(String.t()) :: boolean()
  def edible?(item_name), do: Map.has_key?(@table, item_name)
end
