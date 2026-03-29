defmodule UndercityCli.State do
  @moduledoc """
  Unified application state struct passed through every command dispatch in the Undercity CLI.

  - Holds both game state (player identity, vicinity, AP, HP) and UI state (input buffer, message log, scroll offset)
  - Commands receive and return a `State`, mutating only the fields they care about
  - `selection` is set to a `%View.Selection{}` when a command needs interactive input; `nil` when idle
  - `gateway` is the module used for all server calls, injected at startup to allow test mocking
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
    selection: nil,
    log_scroll: 0
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
          selection: term() | nil,
          log_scroll: non_neg_integer()
        }

  @doc """
  Clears the active selection overlay, setting `state.selection` to `nil`.
  """
  def clear_selection(state), do: %{state | selection: nil}
end
