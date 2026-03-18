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

  @doc """
  Applies a validated heal, returning the amount actually healed.

  Returns `{:ok, healed, new_health}` where `healed` is clamped to the
  remaining HP deficit (may be 0 if already at max). Returns
  `{:error, :collapsed}` if the player is at 0 HP.
  """
  @spec heal(t(), pos_integer()) :: {:ok, non_neg_integer(), t()} | {:error, :collapsed}
  def heal(%__MODULE__{hp: 0}, _amount), do: {:error, :collapsed}

  def heal(%__MODULE__{hp: hp} = health, amount) do
    healed = min(amount, @max - hp)
    {:ok, healed, %{health | hp: hp + healed}}
  end

  @doc """
  Applies a health effect. Heals or damages, clamped to 0..max.
  """
  @spec apply_effect(t(), {:heal, pos_integer()} | {:damage, pos_integer()}) :: t()
  def apply_effect(%__MODULE__{hp: hp} = health, {:heal, amount}), do: %{health | hp: min(hp + amount, @max)}

  def apply_effect(%__MODULE__{hp: hp} = health, {:damage, amount}), do: %{health | hp: max(hp - amount, 0)}
end
