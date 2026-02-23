defmodule UndercityCli.Commands.DropTest do
  use ExUnit.Case, async: true
  use Mimic

  alias UndercityCli.Commands.Drop
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.InventorySelector
  alias UndercityServer.Gateway

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "bare drop cancelled returns continue with unchanged state" do
    expect(Gateway, :check_inventory, fn "player1" -> [] end)
    expect(InventorySelector, :select, fn [], "Drop which item?" -> :cancel end)
    assert {:continue, new_state} = Drop.dispatch("drop", @state, Gateway, MessageBuffer, InventorySelector)
    assert new_state == @state
  end

  test "bare drop with selection succeeds and returns continue with info and updated ap" do
    expect(Gateway, :check_inventory, fn "player1" -> [] end)
    expect(InventorySelector, :select, fn [], "Drop which item?" -> {:ok, 0} end)
    expect(Gateway, :drop_item, fn "player1", 0 -> {:ok, "Sword", 9} end)
    expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
    assert {:continue, new_state} = Drop.dispatch("drop", @state, Gateway, MessageBuffer, InventorySelector)
    assert new_state.ap == 9
  end

  test "indexed drop succeeds and returns continue with info and updated ap" do
    expect(Gateway, :drop_item, fn "player1", 0 -> {:ok, "Sword", 9} end)
    expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
    assert {:continue, new_state} = Drop.dispatch({"drop", "1"}, @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "invalid index string returns continue with warning and unchanged state" do
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert {:continue, new_state} = Drop.dispatch({"drop", "0"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "gateway invalid index returns continue with warning and unchanged state" do
    expect(Gateway, :drop_item, fn "player1", 0 -> {:error, :invalid_index} end)
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert {:continue, new_state} = Drop.dispatch({"drop", "1"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
