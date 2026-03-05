defmodule UndercityCli.Commands.Inventory do
  @moduledoc "Handles the inventory command."

  alias UndercityCli.MessageBuffer

  def usage, do: "inventory (or i)"

  def dispatch(_verb, state) do
    case state.gateway.check_inventory(state.player_id) do
      [] -> MessageBuffer.info("Your inventory is empty.")
      items -> MessageBuffer.info("Inventory: #{Enum.map_join(items, ", ", & &1.name)}")
    end

    state
  end
end
