defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.

  Delegates to submodules:
  - `View.Surroundings` — neighbourhood grid
  - `View.BlockDescription` — block text, scribbles, people
  - `View.Constitution` — AP/HP tier status
  - `View.Status` — generic message formatting
  """

  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Constitution
  alias UndercityCli.View.Status
  alias UndercityCli.View.Surroundings

  defdelegate render_surroundings(vicinity), to: Surroundings, as: :render
  defdelegate render_current_block(vicinity, current_player), to: BlockDescription, as: :render
  defdelegate render_constitution(ap, hp), to: Constitution, as: :render
  defdelegate render_constitution(ap, hp, old_ap), to: Constitution, as: :render
  defdelegate render_constitution(ap, hp, old_ap, old_hp), to: Constitution, as: :render

  defdelegate format_message(message, category \\ :info), to: Status

  defdelegate scribble_surface(vicinity), to: BlockDescription
end
