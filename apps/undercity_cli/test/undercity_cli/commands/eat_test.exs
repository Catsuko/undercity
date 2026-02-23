defmodule UndercityCli.Commands.EatTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Eat
  alias UndercityCli.View.InventorySelector

  test "bare eat cancelled returns continue with unchanged state" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(InventorySelector, :select, fn [], "Eat which item?" -> :cancel end)
    assert {:continue, new_state} = Eat.dispatch("eat", @state, Gateway, MessageBuffer, InventorySelector)
    assert new_state == @state
  end

  test "bare eat with selection succeeds and returns continue with success message and updated ap and hp" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(InventorySelector, :select, fn [], "Eat which item?" -> {:ok, 0} end)
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, %{name: "Bread"}, :restore, 9, 11} end)
    expect(MessageBuffer, :success, fn "Ate a Bread." -> :ok end)
    assert {:continue, new_state} = Eat.dispatch("eat", @state, Gateway, MessageBuffer, InventorySelector)
    assert new_state.ap == 9
    assert new_state.hp == 11
  end

  test "successful eat returns continue with success message and updated ap and hp" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, %{name: "Bread"}, :restore, 9, 11} end)
    expect(MessageBuffer, :success, fn "Ate a Bread." -> :ok end)
    assert {:continue, new_state} = Eat.dispatch({"eat", "1"}, @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
    assert new_state.hp == 11
  end

  test "not edible returns continue with warning and unchanged state" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :not_edible, "Rock"} end)
    expect(MessageBuffer, :warn, fn "You can't eat Rock." -> :ok end)
    assert {:continue, new_state} = Eat.dispatch({"eat", "1"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "invalid index string returns continue with warning and unchanged state" do
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert {:continue, new_state} = Eat.dispatch({"eat", "0"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "gateway invalid index returns continue with warning and unchanged state" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :invalid_index} end)
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert {:continue, new_state} = Eat.dispatch({"eat", "1"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
