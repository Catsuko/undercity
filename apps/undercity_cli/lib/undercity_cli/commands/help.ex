defmodule UndercityCli.Commands.Help do
  @moduledoc """
  Handles the help command.
  """

  alias UndercityCli.Commands
  alias UndercityCli.GameState

  def usage, do: "help"

  def dispatch(_verb, state, _gateway, message_buffer) do
    message_buffer.info(Commands.usage_hints())
    GameState.continue(state)
  end
end
