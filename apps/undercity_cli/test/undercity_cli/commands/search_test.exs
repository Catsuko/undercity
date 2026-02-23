defmodule UndercityCli.Commands.SearchTest do
  use ExUnit.Case, async: true
  use Mimic

  alias UndercityCli.Commands.Search
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "found item returns continue with success message and updated ap" do
    expect(Gateway, :perform, fn "player1", "block1", :search, _ -> {:ok, {:found, %{name: "Coin"}}, 9} end)
    expect(MessageBuffer, :success, fn "You found Coin!" -> :ok end)
    assert {:continue, new_state} = Search.dispatch("search", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "found but inventory full returns continue with warning and updated ap" do
    expect(Gateway, :perform, fn "player1", "block1", :search, _ -> {:ok, {:found_but_full, %{name: "Coin"}}, 9} end)
    expect(MessageBuffer, :warn, fn "You found Coin, but your inventory is full." -> :ok end)
    assert {:continue, new_state} = Search.dispatch("search", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "nothing found returns continue with warning and updated ap" do
    expect(Gateway, :perform, fn "player1", "block1", :search, _ -> {:ok, :nothing, 9} end)
    expect(MessageBuffer, :warn, fn "You find nothing." -> :ok end)
    assert {:continue, new_state} = Search.dispatch("search", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end
end
