defmodule FoundItemGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :search, _), do: {:ok, {:found, %{name: "Coin"}}, 9}
end

defmodule FoundButFullGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :search, _), do: {:ok, {:found_but_full, %{name: "Coin"}}, 9}
end

defmodule UndercityCli.Commands.SearchTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands.Search
  alias UndercityCli.GameState

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "found item returns continue with success message and updated ap" do
    assert {:continue, new_state} = Search.dispatch("search", @state, FoundItemGateway, FakeMessageBuffer)
    assert new_state.ap == 9
    assert_received {:success, "You found Coin!"}
  end

  test "found but inventory full returns continue with warning and updated ap" do
    assert {:continue, new_state} = Search.dispatch("search", @state, FoundButFullGateway, FakeMessageBuffer)
    assert new_state.ap == 9
    assert_received {:warn, "You found Coin, but your inventory is full."}
  end

  test "nothing found returns continue with warning and updated ap" do
    assert {:continue, new_state} = Search.dispatch("search", @state, FakeGateway, FakeMessageBuffer)
    assert new_state.ap == 9
    assert_received {:warn, "You find nothing."}
  end
end
