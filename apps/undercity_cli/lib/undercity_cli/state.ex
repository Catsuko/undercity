defmodule UndercityCli.State do
  @moduledoc """
  The unified app state for the Undercity CLI TEA application.

  Consolidates game state and UI state into a single struct passed through
  all command dispatch functions. Replaces the separate GameState struct and
  the plain map used by App.

  Commands take and return a State, updating whatever fields they touch.
  When a command needs user selection (e.g. bare `drop`, `eat`, `attack`),
  it opens a `%View.Selection{}` in `state.selection` via `Commands.Selection`.
  App renders an overlay and re-dispatches via the selection's `on_confirm`
  callback once the user confirms.
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
    selection: nil
  ]

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
          selection: term() | nil
        }

  @doc "Clears the active selection overlay."
  def clear_selection(state), do: %{state | selection: nil}
end
