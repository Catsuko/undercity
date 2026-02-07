defmodule UndercityCore.Person do
  @moduledoc """
  A person in the undercity.
  """

  @enforce_keys [:id, :name]
  defstruct [:id, :name]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t()
        }

  @spec new(String.t()) :: t()
  def new(name) when is_binary(name) do
    %__MODULE__{
      id: generate_id(),
      name: name
    }
  end

  defp generate_id do
    8 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end
end
