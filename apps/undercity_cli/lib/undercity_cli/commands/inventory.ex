defmodule UndercityCli.Commands.Inventory do
  @moduledoc """
  Handles the inventory command.
  """

  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  def dispatch(_verb, player_id, _vicinity, ap, hp) do
    case Gateway.check_inventory(player_id) do
      [] -> MessageBuffer.info("Your inventory is empty.")
      items -> MessageBuffer.info("Inventory: #{Enum.map_join(items, ", ", & &1.name)}")
    end

    {:acted, ap, hp}
  end
end
