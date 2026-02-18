defmodule UndercityCli.View.Status do
  @moduledoc """
  Generic status message formatting for the CLI.
  """

  @success_color IO.ANSI.color(108)
  @info_color IO.ANSI.color(67)
  @warning_color IO.ANSI.color(131)

  def format_message(message, category \\ :info)

  def format_message(message, category) do
    color = message_color(category)
    Owl.Data.tag(["▸ ", message], color)
  end

  defp message_color(:success), do: @success_color
  defp message_color(:info), do: @info_color
  defp message_color(:warning), do: @warning_color
end
