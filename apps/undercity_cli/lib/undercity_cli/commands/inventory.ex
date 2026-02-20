defmodule UndercityCli.Commands.Inventory do
  @moduledoc """
  Handles the inventory command.
  """

  alias UndercityCli.GameState

  def dispatch(_verb, state, gateway, message_buffer) do
    case gateway.check_inventory(state.player_id) do
      [] -> message_buffer.info("Your inventory is empty.")
      items -> message_buffer.info("Inventory: #{Enum.map_join(items, ", ", & &1.name)}")
    end

    GameState.continue(state)
  end
end
