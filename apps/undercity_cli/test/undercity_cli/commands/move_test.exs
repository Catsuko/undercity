defmodule UndercityCli.Commands.MoveTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Move

  test "successful move returns moved with updated vicinity and ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :move, _ -> {:ok, {:ok, %{id: "dest_block"}}, 9} end)
    assert {:moved, new_state} = Move.dispatch("north", @state, Gateway, MessageBuffer)
    assert new_state.vicinity.id == "dest_block"
    assert new_state.ap == 9
  end

  test "no exit returns continue with warning and updated ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :move, _ -> {:ok, {:error, :no_exit}, 9} end)
    expect(MessageBuffer, :warn, fn "You can't go that way." -> :ok end)
    assert {:continue, new_state} = Move.dispatch("north", @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end
end
