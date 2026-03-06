defmodule UndercityCli.State do
  @moduledoc """
  The unified app state for the Undercity CLI TEA application.

  Consolidates game state and UI state into a single struct passed through
  all command dispatch functions. Replaces the separate GameState struct and
  the plain map used by App.

  Commands take and return a State, updating whatever fields they touch.
  When a command needs user selection (e.g. bare `drop`, `eat`, `attack`),
  it calls `pending/3` to record the command context, then `select/3` to
  attach the display data. App renders an overlay and re-dispatches with the
  chosen index once the user confirms.
  """

  defstruct [
    :player_id,
    :player_name,
    :vicinity,
    :ap,
    :hp,
    :input,
    :message_log,
    :gateway,
    :window_width,
    pending: nil
  ]

  @type pending :: %{
          command: String.t(),
          args: list(),
          label: String.t(),
          choices: list(),
          cursor: non_neg_integer()
        }

  @type t :: %__MODULE__{
          player_id: String.t(),
          player_name: String.t(),
          vicinity: term(),
          ap: integer(),
          hp: integer(),
          input: String.t(),
          message_log: list(),
          gateway: module(),
          window_width: non_neg_integer(),
          pending: pending() | nil
        }

  @doc """
  Sets the pending command context. Called by a command clause that needs
  selection before it can execute.
  """
  def pending(state, command, args) do
    %{state | pending: Map.merge(state.pending || %{}, %{command: command, args: args})}
  end

  @doc """
  Adds selection display data (label + choices) to the current pending context.
  Always called immediately after `pending/3`.
  """
  def select(state, label, choices) do
    %{state | pending: Map.merge(state.pending || %{}, %{label: label, choices: choices, cursor: 0})}
  end

  @doc "Clears any pending selection state, returning the state to normal mode."
  def clear_pending(state), do: %{state | pending: nil}
end
