defmodule UndercityCore.Health do
  @moduledoc """
  Pure domain logic for player health.

  Players have a health pool with a fixed maximum. Health starts at max
  and can be reduced or restored, but never exceeds the cap.
  """

  @max 50

  defstruct [:hp]

  @type t :: %__MODULE__{
          hp: non_neg_integer()
        }

  @doc """
  Returns a fresh health struct at maximum HP.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{hp: @max}

  @doc """
  Returns the maximum health a player can have.
  """
  @spec max() :: non_neg_integer()
  def max, do: @max

  @doc """
  Returns the current HP value from the struct.
  """
  @spec current(t()) :: non_neg_integer()
  def current(%__MODULE__{hp: hp}), do: hp
end
