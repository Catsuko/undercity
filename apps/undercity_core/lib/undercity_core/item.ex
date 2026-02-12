defmodule UndercityCore.Item do
  @moduledoc """
  An item that can be found and carried in the undercity.
  """

  @enforce_keys [:name]
  defstruct [:name]

  @type t :: %__MODULE__{
          name: String.t()
        }

  @spec new(String.t()) :: t()
  def new(name) when is_binary(name) do
    %__MODULE__{name: name}
  end
end
