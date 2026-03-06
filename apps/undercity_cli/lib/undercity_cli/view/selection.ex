defmodule UndercityCli.View.Selection do
  @moduledoc """
  Renders the selection overlay panel shown when a command requires the player
  to choose from a list of items.
  """

  import Ratatouille.View

  def render(%{label: label, choices: choices, cursor: cursor}) do
    panel title: label, padding: 1 do
      choices
      |> Enum.with_index()
      |> Enum.map(fn {item, i} -> item_label(item, i == cursor) end)
    end
  end

  defp item_label(item, true), do: label(content: "> #{item.name}", color: :cyan)
  defp item_label(item, false), do: label(content: "  #{item.name}")
end
