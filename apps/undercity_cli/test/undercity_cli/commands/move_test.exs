defmodule NoExitGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :move, _direction), do: {:ok, {:error, :no_exit}, 9}
end

defmodule UndercityCli.Commands.MoveTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands.Move
  alias UndercityCli.GameState

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  test "successful move returns moved with updated vicinity and ap" do
    assert {:moved, new_state} = Move.dispatch("north", @state, FakeGateway, FakeMessageBuffer)
    assert new_state.vicinity.id == "dest_block"
    assert new_state.ap == 9
  end

  test "no exit returns continue with warning and updated ap" do
    assert {:continue, new_state} = Move.dispatch("north", @state, NoExitGateway, FakeMessageBuffer)
    assert new_state.ap == 9
    assert_received {:warn, "You can't go that way."}
  end
end
