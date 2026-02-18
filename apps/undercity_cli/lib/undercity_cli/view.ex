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
    render(vicinity, player, Constitution.status_messages(ap, hp))
  end

  def render(vicinity, player, messages \\ []) do
    Screen.update(vicinity, player, messages)
  end
end
