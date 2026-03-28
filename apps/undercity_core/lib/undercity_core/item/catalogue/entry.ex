defmodule UndercityCore.Item.Catalogue.Entry do
  @moduledoc """
  A single entry in the item catalogue.

  - `id` is the canonical atom identifier used internally across `LootTable`, `Combat.Weapon`, and `Item.Food`
  - `name` is the display string written into `Item.t()` structs
  - `default_uses` is the number of uses a consumable item starts with; nil for non-consumable items
  - `weapon` and `edible` are informational flags — behaviour dispatch lives in the respective domain modules
  """
  @enforce_keys [:id, :name]
  defstruct [:id, :name, :default_uses, weapon: false, edible: false]

  @type t :: %__MODULE__{
          id: atom(),
          name: String.t(),
          default_uses: pos_integer() | nil,
          weapon: boolean(),
          edible: boolean()
        }
end
