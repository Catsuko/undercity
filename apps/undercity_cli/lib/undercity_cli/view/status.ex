defmodule UndercityCli.View.Status do
  @moduledoc """
  Formats `{text, category}` message tuples into coloured Ratatouille label elements for the log panel.

  - Maps `:success` to green, `:info` to white, and `:warning` to red
  - Prepends a `▸` bullet to each message for visual consistency
  """

  import Ratatouille.View

  @doc """
  Formats a message string into a coloured Ratatouille label element.

  - `category` defaults to `:info` when omitted.
  - Returns a `label/1` element with a `▸` prefix and the colour for the given category.
  """
  def format_message(message, category \\ :info)

  def format_message(message, category) do
    color = message_color(category)
    label(content: "▸ #{message}", color: color, wrap: false)
  end

  defp message_color(:success), do: Ratatouille.Constants.color(:green)
  defp message_color(:info), do: Ratatouille.Constants.color(:white)
  defp message_color(:warning), do: Ratatouille.Constants.color(:red)
end
