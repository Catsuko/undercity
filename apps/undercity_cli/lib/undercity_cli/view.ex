defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.

  Delegates to submodules:
  - `View.Surroundings` — neighbourhood grid
  - `View.BlockDescription` — block text, scribbles, people
  - `View.Constitution` — AP/HP tier status
  - `View.Status` — generic message formatting
  """

  alias UndercityCli.View.Constitution
  alias UndercityCli.View.Screen

  defdelegate read_input(), to: Screen

  def init(vicinity, player, ap, hp) do
    Screen.init()
    render_surroundings(vicinity)
    render_description(vicinity, player)
    render_messages(Constitution.status_messages(ap, hp))
  end

  def render_surroundings(vicinity) do
    Screen.update_surroundings(vicinity)
  end

  def render_description(vicinity, player) do
    Screen.update_description(vicinity, player)
  end

  def render_messages(messages) do
    Screen.update_messages(messages)
  end
end
