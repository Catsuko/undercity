defmodule UndercityCli.Commands.SearchTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Search

  test "found item returns continue with success message and updated ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, {:found, %{name: "Coin"}}, 9} end)
    expect(MessageBuffer, :success, fn "You found Coin!" -> :ok end)
    assert {:continue, new_state} = Search.dispatch("search", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "found but inventory full returns continue with warning and updated ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, {:found_but_full, %{name: "Coin"}}, 9} end)
    expect(MessageBuffer, :warn, fn "You found Coin, but your inventory is full." -> :ok end)
    assert {:continue, new_state} = Search.dispatch("search", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "nothing found returns continue with warning and updated ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, :nothing, 9} end)
    expect(MessageBuffer, :warn, fn "You find nothing." -> :ok end)
    assert {:continue, new_state} = Search.dispatch("search", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end
end
