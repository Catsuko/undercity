defmodule UndercityCli.Commands.EatTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Eat

  @items [%{name: "Bread"}, %{name: "Meat"}]

  test "bare eat with empty inventory warns and returns model unchanged" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(MessageBuffer, :warn, fn "Your inventory is empty." -> :ok end)
    assert Eat.dispatch("eat", @state) == @state
  end

  test "bare eat with items opens selection overlay" do
    expect(Gateway, :check_inventory, fn @player_id -> @items end)
    result = Eat.dispatch("eat", @state)
    assert result.selection.label == "Eat which item?"
    assert result.selection.choices == @items
  end

  test "indexed eat succeeds and returns model with updated ap and hp" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, 9, 11} end)
    result = Eat.dispatch({"eat", "1"}, @state)
    assert result.ap == 9
    assert result.hp == 11
  end

  test "re-dispatch after selection executes eat" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, 9, 11} end)
    result = Eat.dispatch({"eat", 0}, @state)
    assert result.ap == 9
    assert result.hp == 11
  end

  test "not edible returns model unchanged" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :not_edible, "Rock"} end)
    assert Eat.dispatch({"eat", "1"}, @state) == @state
  end

  test "invalid index string returns model unchanged with warning" do
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert Eat.dispatch({"eat", "0"}, @state) == @state
  end

  test "gateway noop on invalid index updates ap and hp" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, 9, 11} end)
    result = Eat.dispatch({"eat", "1"}, @state)
    assert result.ap == 9
    assert result.hp == 11
  end
end
