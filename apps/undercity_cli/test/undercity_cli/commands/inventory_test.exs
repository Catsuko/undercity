defmodule UndercityCli.Commands.InventoryTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Inventory

  test "empty inventory returns model unchanged with info message" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
    assert Inventory.dispatch("inventory", @state) == @state
  end

  test "items present returns model unchanged with item list" do
    expect(Gateway, :check_inventory, fn @player_id -> [%{name: "Sword"}, %{name: "Bread"}] end)
    expect(MessageBuffer, :info, fn "Inventory: Sword, Bread" -> :ok end)
    assert Inventory.dispatch("inventory", @state) == @state
  end
end
