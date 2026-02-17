defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.

  Delegates to submodules:
  - `View.Surroundings` — neighbourhood grid
  - `View.BlockDescription` — block text, scribbles, people
  - `View.Constitution` — AP/HP tier status
  - `View.Status` — generic message formatting
  """

  alias UndercityCli.View.Screen

  defdelegate init(), to: Screen
  defdelegate read_input(), to: Screen
  defdelegate teardown(), to: Screen

  def render(vicinity, player, messages \\ []) do
    Screen.update(vicinity, player, messages)
  end
end
