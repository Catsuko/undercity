defmodule UndercityCli.Commands.Help do
  @moduledoc """
  Handles the `help` command, printing all registered command usage hints to the message log.
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer

  @doc "Returns the usage hint string for the help command."
  def usage, do: "help"

  @doc """
  Dispatches the help command, pushing all usage hints as an info message and returning state unchanged.
  """
  def dispatch(_verb, state) do
    MessageBuffer.info(Commands.usage_hints())
    state
  end
end
