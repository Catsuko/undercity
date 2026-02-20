defmodule UndercityCli.GameState do
  @moduledoc """
  The game state maintained by the game loop.

  Passed through command dispatch and returned as a tagged tuple
  indicating what changed: `{:moved, state}` when the player's location
  changed, or `{:continue, state}` for all other actions.
  """

  defstruct [:player_id, :vicinity, :ap, :hp]

  @type t :: %__MODULE__{
          player_id: String.t(),
          vicinity: term(),
          ap: term(),
          hp: term()
        }

  @doc "Wraps an unchanged state as an :continue result."
  def continue(%__MODULE__{} = state), do: {:continue, state}

  @doc "Wraps a state with updated AP and HP as an :continue result."
  def continue(%__MODULE__{} = state, new_ap, new_hp), do: {:continue, %{state | ap: new_ap, hp: new_hp}}

  @doc "Wraps a state with updated vicinity, AP and HP as a :moved result."
  def moved(%__MODULE__{} = state, new_vicinity, new_ap, new_hp),
    do: {:moved, %{state | vicinity: new_vicinity, ap: new_ap, hp: new_hp}}
end
