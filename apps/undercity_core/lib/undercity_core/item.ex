defmodule UndercityCore.Item do
  @moduledoc """
  An item that can be found and carried in the undercity.
  """

  @enforce_keys [:name]
  defstruct [:name, :uses]

  @type t :: %__MODULE__{
          name: String.t(),
          uses: non_neg_integer() | nil
        }

  @spec new(String.t()) :: t()
  def new(name) when is_binary(name) do
    %__MODULE__{name: name}
  end

  @spec new(String.t(), non_neg_integer()) :: t()
  def new(name, uses) when is_binary(name) and is_integer(uses) and uses > 0 do
    %__MODULE__{name: name, uses: uses}
  end

  @doc """
  Decrements the uses of a consumable item.
  Returns `{:ok, item}` with decremented uses, or `:spent` when uses reach 0.
  Items with `nil` uses are non-consumable and always return `{:ok, item}`.
  """
  @spec use(t()) :: {:ok, t()} | :spent
  def use(%__MODULE__{uses: nil} = item), do: {:ok, item}
  def use(%__MODULE__{uses: 1}), do: :spent
  def use(%__MODULE__{uses: uses} = item) when uses > 1, do: {:ok, %{item | uses: uses - 1}}
end
