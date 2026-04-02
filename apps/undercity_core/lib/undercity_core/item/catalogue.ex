defmodule UndercityCore.Item.Catalogue do
  @moduledoc """
  The authoritative registry of all item identities.

  Each item has a canonical atom identifier used internally across
  LootTable, Combat.Weapon, and Item.Food. The `name` field is the display
  string written into `Item.t()` structs.

  Domain flags (`weapon`, `edible`) are informational and not used for
  behaviour dispatch — each domain module still owns its own logic.
  """

  alias UndercityCore.Item.Catalogue.Entry

  @entries [
    %Entry{id: :iron_pipe, name: "Iron Pipe", weapon: true, action: :attack},
    %Entry{id: :chalk, name: "Chalk", default_uses: 5, action: :scribble},
    %Entry{id: :mushroom, name: "Mushroom", edible: true, action: :eat},
    %Entry{id: :junk, name: "Junk"},
    %Entry{id: :salve, name: "Salve", default_uses: 1, action: :heal}
  ]

  @by_id Map.new(@entries, fn e -> {e.id, e} end)
  @by_name Map.new(@entries, fn e -> {e.name, e} end)

  @doc "Returns the Entry for the given atom id, or `:not_found`."
  @spec fetch(atom()) :: {:ok, Entry.t()} | :not_found
  def fetch(id) when is_atom(id) do
    case Map.get(@by_id, id) do
      nil -> :not_found
      entry -> {:ok, entry}
    end
  end

  @doc "Returns the Entry whose name matches the given string, or `:not_found`."
  @spec fetch_by_name(String.t()) :: {:ok, Entry.t()} | :not_found
  def fetch_by_name(name) when is_binary(name) do
    case Map.get(@by_name, name) do
      nil -> :not_found
      entry -> {:ok, entry}
    end
  end

  @doc "Returns the display name string for the given atom id. Raises if unknown."
  @spec name!(atom()) :: String.t()
  def name!(id) when is_atom(id) do
    Map.fetch!(@by_id, id).name
  end

  @doc "Returns all catalogue entries."
  @spec all() :: [Entry.t()]
  def all, do: @entries
end
