defmodule UndercityCli.Commands.SearchTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Search

  test "found item returns model with updated ap and success message" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, {:found, %{name: "Coin"}}, 9} end)
    expect(MessageBuffer, :success, fn "You found Coin!" -> :ok end)
    result = Search.dispatch("search", @state)
    assert result.ap == 9
  end

  test "found but inventory full returns model with updated ap and warning" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, {:found_but_full, %{name: "Coin"}}, 9} end)
    expect(MessageBuffer, :warn, fn "You found Coin, but your inventory is full." -> :ok end)
    result = Search.dispatch("search", @state)
    assert result.ap == 9
  end

  test "nothing found returns model with updated ap and warning" do
    expect(Gateway, :perform, fn @player_id, @block_id, :search, _ -> {:ok, :nothing, 9} end)
    expect(MessageBuffer, :warn, fn "You find nothing." -> :ok end)
    result = Search.dispatch("search", @state)
    assert result.ap == 9
  end
end
