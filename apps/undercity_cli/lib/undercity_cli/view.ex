defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.

  Delegates to submodules:
  - `View.Surroundings` — neighbourhood grid
  - `View.BlockDescription` — block text, scribbles, people
  - `View.Constitution` — AP/HP tier status
  - `View.Status` — generic message formatting
  """

  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.Constitution
  alias UndercityCli.View.Screen

  defdelegate read_input(), to: Screen

  def init(vicinity, player, ap, hp) do
    case MessageBuffer.start_link() do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    Screen.init()
    render_surroundings(vicinity)
    render_description(vicinity, player)
    MessageBuffer.push(Constitution.status_messages(ap, hp))
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
