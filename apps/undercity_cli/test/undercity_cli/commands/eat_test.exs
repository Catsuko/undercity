defmodule EatSuccessGateway do
  @moduledoc false
  def check_inventory(_player_id), do: []
  def perform(_player_id, _block_id, :eat, _index), do: {:ok, %{name: "Bread"}, :restore, 9, 11}
end

defmodule NotEdibleGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :eat, _index), do: {:error, :not_edible, "Rock"}
end

defmodule UndercityCli.Commands.EatTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands.Eat
  alias UndercityCli.GameState

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "bare eat cancelled returns continue with unchanged state" do
    assert {:continue, new_state} = Eat.dispatch("eat", @state, EatSuccessGateway, FakeMessageBuffer, CancelSelector)
    assert new_state == @state
  end

  test "bare eat with selection succeeds and returns continue with success message and updated ap and hp" do
    assert {:continue, new_state} = Eat.dispatch("eat", @state, EatSuccessGateway, FakeMessageBuffer, SelectFirstSelector)
    assert new_state.ap == 9
    assert new_state.hp == 11
    assert_received {:success, "Ate a Bread."}
  end

  test "successful eat returns continue with success message and updated ap and hp" do
    assert {:continue, new_state} = Eat.dispatch({"eat", "1"}, @state, EatSuccessGateway, FakeMessageBuffer)
    assert new_state.ap == 9
    assert new_state.hp == 11
    assert_received {:success, "Ate a Bread."}
  end

  test "not edible returns continue with warning and unchanged state" do
    assert {:continue, new_state} = Eat.dispatch({"eat", "1"}, @state, NotEdibleGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:warn, "You can't eat Rock."}
  end

  test "invalid index string returns continue with warning and unchanged state" do
    assert {:continue, new_state} = Eat.dispatch({"eat", "0"}, @state, FakeGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:warn, "Invalid item selection."}
  end

  test "gateway invalid index returns continue with warning and unchanged state" do
    assert {:continue, new_state} = Eat.dispatch({"eat", "1"}, @state, FakeGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:warn, "Invalid item selection."}
  end
end
