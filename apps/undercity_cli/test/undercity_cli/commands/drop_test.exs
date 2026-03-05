defmodule UndercityCli.Commands.DropTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Drop

  @items [%{name: "Sword"}, %{name: "Bread"}]

  test "bare drop with empty inventory warns and returns model unchanged" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(MessageBuffer, :warn, fn "Your inventory is empty." -> :ok end)
    assert Drop.dispatch("drop", @state) == @state
  end

  test "bare drop with items sets pending on model" do
    expect(Gateway, :check_inventory, fn @player_id -> @items end)
    result = Drop.dispatch("drop", @state)
    assert result.pending.command == "drop"
    assert result.pending.args == []
    assert result.pending.label == "Drop which item?"
    assert result.pending.choices == @items
  end

  test "indexed drop succeeds and returns model with updated ap" do
    expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, "Sword", 9} end)
    expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
    result = Drop.dispatch({"drop", "1"}, @state)
    assert result.ap == 9
  end

  test "re-dispatch after selection executes drop" do
    expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, "Sword", 9} end)
    expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
    result = Drop.dispatch("drop", 0, @state)
    assert result.ap == 9
  end

  test "invalid index string returns model unchanged with warning" do
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert Drop.dispatch({"drop", "0"}, @state) == @state
  end

  test "gateway invalid index returns model unchanged with warning" do
    expect(Gateway, :drop_item, fn @player_id, 0 -> {:error, :invalid_index} end)
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert Drop.dispatch({"drop", "1"}, @state) == @state
  end
end
