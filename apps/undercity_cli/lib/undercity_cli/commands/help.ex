defmodule UndercityCli.Commands.Help do
  @moduledoc "Handles the help command."

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer

  def usage, do: "help"

  def dispatch(_verb, state) do
    MessageBuffer.info(Commands.usage_hints())
    state
  end
end
