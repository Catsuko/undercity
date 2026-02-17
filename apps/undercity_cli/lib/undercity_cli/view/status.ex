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
    ["▸ ", message] |> Owl.Data.tag(color) |> to_owl_string()
  end

  def render_message(nil), do: :ok
  def render_message({message, category}), do: render_message(message, category)

  def render_message(message, category) do
    IO.puts(format_message(message, category))
  end

  defp message_color(:success), do: @success_color
  defp message_color(:info), do: @info_color
  defp message_color(:warning), do: @warning_color

  defp to_owl_string(data), do: data |> Owl.Data.to_chardata() |> IO.iodata_to_binary()
end
