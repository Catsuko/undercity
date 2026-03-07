defmodule UndercityCli.Commands.EatTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Eat

  @items [%{name: "Bread"}, %{name: "Meat"}]

  test "bare eat with empty inventory warns and returns model unchanged" do
    expect(Gateway, :check_inventory, fn @player_id -> [] end)
    expect(MessageBuffer, :warn, fn "Your inventory is empty." -> :ok end)
    assert Eat.dispatch("eat", @state) == @state
  end

  test "bare eat with items sets pending on model" do
    expect(Gateway, :check_inventory, fn @player_id -> @items end)
    result = Eat.dispatch("eat", @state)
    assert result.pending.command == "eat"
    assert result.pending.label == "Eat which item?"
    assert result.pending.choices == @items
  end

  test "indexed eat succeeds and returns model with updated ap and hp" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, %{name: "Bread"}, :restore, 9, 11} end)
    expect(MessageBuffer, :success, fn "Ate a Bread." -> :ok end)
    result = Eat.dispatch({"eat", "1"}, @state)
    assert result.ap == 9
    assert result.hp == 11
  end

  test "re-dispatch after selection executes eat" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, %{name: "Bread"}, :restore, 9, 11} end)
    expect(MessageBuffer, :success, fn "Ate a Bread." -> :ok end)
    result = Eat.dispatch({"eat", 0}, @state)
    assert result.ap == 9
    assert result.hp == 11
  end

  test "not edible returns model unchanged with warning" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :not_edible, "Rock"} end)
    expect(MessageBuffer, :warn, fn "You can't eat Rock." -> :ok end)
    assert Eat.dispatch({"eat", "1"}, @state) == @state
  end

  test "invalid index string returns model unchanged with warning" do
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert Eat.dispatch({"eat", "0"}, @state) == @state
  end

  test "gateway invalid index returns model unchanged with warning" do
    expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :invalid_index} end)
    expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
    assert Eat.dispatch({"eat", "1"}, @state) == @state
  end
end
