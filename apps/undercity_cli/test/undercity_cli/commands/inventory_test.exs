defmodule UndercityCli.Commands.InventoryTest do
  use ExUnit.Case, async: true
  use Mimic

  alias UndercityCli.Commands.Inventory
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "empty inventory returns continue with info message and unchanged state" do
    expect(Gateway, :check_inventory, fn "player1" -> [] end)
    expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
    assert {:continue, new_state} = Inventory.dispatch("inventory", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "items present returns continue with item list and unchanged state" do
    expect(Gateway, :check_inventory, fn "player1" -> [%{name: "Sword"}, %{name: "Bread"}] end)
    expect(MessageBuffer, :info, fn "Inventory: Sword, Bread" -> :ok end)
    assert {:continue, new_state} = Inventory.dispatch("inventory", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
