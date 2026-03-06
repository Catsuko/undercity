defmodule UndercityCli.View.Status do
  @moduledoc """
  Generic status message formatting for the CLI.
  """

  import Ratatouille.View

  def format_message(message, category \\ :info)

  def format_message(message, category) do
    color = message_color(category)
    label(content: "▸ #{message}", color: color, wrap: true)
  end

  defp message_color(:success), do: Ratatouille.Constants.color(:green)
  defp message_color(:info), do: Ratatouille.Constants.color(:white)
  defp message_color(:warning), do: Ratatouille.Constants.color(:red)
end
