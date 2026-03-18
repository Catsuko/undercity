defmodule UndercityCore.Item.Catalogue.Entry do
  @moduledoc false
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
