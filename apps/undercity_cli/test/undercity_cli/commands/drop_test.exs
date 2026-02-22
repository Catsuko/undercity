defmodule DropInvalidIndexGateway do
  @moduledoc false
  def drop_item(_player_id, _index), do: {:error, :invalid_index}
end

defmodule UndercityCli.Commands.DropTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands.Drop
  alias UndercityCli.GameState

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "bare drop cancelled returns continue with unchanged state" do
    assert {:continue, new_state} = Drop.dispatch("drop", @state, FakeGateway, FakeMessageBuffer, CancelSelector)
    assert new_state == @state
  end

  test "bare drop with selection succeeds and returns continue with info and updated ap" do
    assert {:continue, new_state} = Drop.dispatch("drop", @state, FakeGateway, FakeMessageBuffer, SelectFirstSelector)
    assert new_state.ap == 9
    assert_received {:info, "You dropped Sword."}
  end

  test "indexed drop succeeds and returns continue with info and updated ap" do
    assert {:continue, new_state} = Drop.dispatch({"drop", "1"}, @state, FakeGateway, FakeMessageBuffer)
    assert new_state.ap == 9
    assert_received {:info, "You dropped Sword."}
  end

  test "invalid index string returns continue with warning and unchanged state" do
    assert {:continue, new_state} = Drop.dispatch({"drop", "0"}, @state, FakeGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:warn, "Invalid item selection."}
  end

  test "gateway invalid index returns continue with warning and unchanged state" do
    assert {:continue, new_state} =
             Drop.dispatch({"drop", "1"}, @state, DropInvalidIndexGateway, FakeMessageBuffer)

    assert new_state == @state
    assert_received {:warn, "Invalid item selection."}
  end
end
