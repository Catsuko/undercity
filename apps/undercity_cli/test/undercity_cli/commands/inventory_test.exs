defmodule ItemsGateway do
  @moduledoc false
  def check_inventory(_player_id), do: [%{name: "Sword"}, %{name: "Bread"}]
end

defmodule UndercityCli.Commands.InventoryTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands.Inventory
  alias UndercityCli.GameState

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "empty inventory returns continue with info message and unchanged state" do
    assert {:continue, new_state} = Inventory.dispatch("inventory", @state, FakeGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:info, "Your inventory is empty."}
  end

  test "items present returns continue with item list and unchanged state" do
    assert {:continue, new_state} = Inventory.dispatch("inventory", @state, ItemsGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:info, "Inventory: Sword, Bread"}
  end
end
