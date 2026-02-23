defmodule UndercityCli.Commands.InventoryTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Inventory

  test "empty inventory returns continue with info message and unchanged state" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
    assert {:continue, new_state} = Inventory.dispatch("inventory", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "items present returns continue with item list and unchanged state" do
    expect(Gateway, :check_inventory, fn @player_id -> [%{name: "Sword"}, %{name: "Bread"}] end)
    expect(MessageBuffer, :info, fn "Inventory: Sword, Bread" -> :ok end)
    assert {:continue, new_state} = Inventory.dispatch("inventory", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
