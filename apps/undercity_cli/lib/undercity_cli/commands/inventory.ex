defmodule UndercityCli.Commands.Inventory do
  @moduledoc """
  Handles the inventory command.
  """

  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  def dispatch(_verb, state) do
    case Gateway.check_inventory(state.player_id) do
      [] -> MessageBuffer.info("Your inventory is empty.")
      items -> MessageBuffer.info("Inventory: #{Enum.map_join(items, ", ", & &1.name)}")
    end

    GameState.continue(state)
  end
end
