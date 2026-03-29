defmodule UndercityCli.Commands.Inventory do
  @moduledoc """
  Handles the `inventory` command, displaying the player's current item list.
  """

  alias UndercityCli.MessageBuffer

  @doc "Returns the usage hint string for the inventory command."
  def usage, do: "inventory (or i)"

  @doc """
  Dispatches the inventory command, listing all carried items as an info message.

  - Emits a warning if the inventory is empty.
  - Returns state unchanged.
  """
  def dispatch(_verb, state) do
    case state.gateway.check_inventory(state.player_id) do
      [] -> MessageBuffer.info("Your inventory is empty.")
      items -> MessageBuffer.info("Inventory: #{Enum.map_join(items, ", ", & &1.name)}")
    end

    state
  end
end
