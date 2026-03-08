defmodule UndercityCli.View.Selection do
  @moduledoc """
  UI primitive for presenting a navigable list to the player.

  Owns the struct, cursor navigation, confirm/cancel dispatch, and rendering.
  Commands wire selections via `Commands.Selection`, which stores command-specific
  callbacks in `on_confirm` and `on_cancel`. Non-command use cases can set
  their own callbacks directly.
  """

  import Ratatouille.View

  defstruct label: nil, choices: nil, cursor: 0, on_confirm: nil, on_cancel: nil

  @type callback :: (term() -> term())

  @type t :: %__MODULE__{
          label: String.t(),
          choices: list(),
          cursor: non_neg_integer(),
          on_confirm: callback(),
          on_cancel: callback()
        }

  @doc "Moves the cursor up one row, clamping at the first choice."
  def move_up(%__MODULE__{cursor: cursor} = selection) do
    %{selection | cursor: max(0, cursor - 1)}
  end

  @doc "Moves the cursor down one row, clamping at the last choice."
  def move_down(%__MODULE__{cursor: cursor, choices: choices} = selection) do
    %{selection | cursor: min(length(choices) - 1, cursor + 1)}
  end

  @doc "Calls the on_confirm callback with the current state."
  def confirm(%__MODULE__{on_confirm: on_confirm}, state) do
    on_confirm.(state)
  end

  @doc "Calls the on_cancel callback with the current state."
  def cancel(%__MODULE__{on_cancel: on_cancel}, state) do
    on_cancel.(state)
  end

  @doc "Renders the selection overlay panel."
  def render(%__MODULE__{label: label, choices: choices, cursor: cursor}) do
    panel title: label, padding: 1 do
      choices
      |> Enum.with_index()
      |> Enum.map(fn {item, i} -> item_label(item, i == cursor) end)
    end
  end

  defp item_label(item, true), do: label(content: "> #{item.name}", color: :cyan)
  defp item_label(item, false), do: label(content: "  #{item.name}")
end
