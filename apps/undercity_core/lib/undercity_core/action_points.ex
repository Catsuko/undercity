defmodule UndercityCore.ActionPoints do
  @moduledoc """
  Pure domain logic for the action point (AP) system.

  Players have a pool of AP that is spent when performing actions and
  regenerates lazily over time. This module owns the rules: maximum AP,
  regeneration rate, and the spend/regen computations.
  """

  @max 50
  @regen_interval 1800

  defstruct [:ap, :updated_at]

  @type t :: %__MODULE__{
          ap: non_neg_integer(),
          updated_at: integer()
        }

  @doc """
  Returns a fresh action points struct at maximum AP.
  """
  @spec new(integer()) :: t()
  def new(now \\ System.os_time(:second)), do: %__MODULE__{ap: @max, updated_at: now}

  @doc """
  Returns the maximum action points a player can have.
  """
  @spec max() :: non_neg_integer()
  def max, do: @max

  @doc """
  Applies lazy regeneration and returns the updated struct.
  Regenerates 1 AP per #{@regen_interval}-second interval elapsed, capped at #{@max}.
  """
  @spec regenerate(t(), integer()) :: t()
  def regenerate(%__MODULE__{ap: ap, updated_at: updated_at} = action_points, now \\ System.os_time(:second)) do
    elapsed = now - updated_at
    gained = div(elapsed, @regen_interval)
    %{action_points | ap: min(ap + gained, @max)}
  end

  @doc """
  Returns the current AP value from the struct.
  """
  @spec current(t()) :: non_neg_integer()
  def current(%__MODULE__{ap: ap}), do: ap

  @doc """
  Attempts to spend AP. Returns `{:ok, updated_struct}` or `{:error, :exhausted}`.
  """
  @spec spend(t(), pos_integer(), integer()) :: {:ok, t()} | {:error, :exhausted}
  def spend(action_points, cost, now \\ System.os_time(:second))

  def spend(%__MODULE__{ap: ap} = action_points, cost, now) when ap >= cost do
    {:ok, %{action_points | ap: ap - cost, updated_at: now}}
  end

  def spend(%__MODULE__{}, _cost, _now), do: {:error, :exhausted}
end
