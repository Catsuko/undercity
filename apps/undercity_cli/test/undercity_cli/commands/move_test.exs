defmodule UndercityCli.Commands.MoveTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Move

  test "successful move returns model with updated vicinity and ap" do
    dest = %Vicinity{id: "dest_block"}
    expect(Gateway, :perform, fn @player_id, @block_id, :move, _ -> {:ok, {:ok, dest}, 9} end)
    expect(MessageBuffer, :info, fn "You move to " <> _ -> :ok end)
    result = Move.dispatch("north", @state)
    assert result.vicinity.id == "dest_block"
    assert result.ap == 9
  end

  test "no exit returns model with warning and updated ap" do
    expect(Gateway, :perform, fn @player_id, @block_id, :move, _ -> {:ok, {:error, :no_exit}, 9} end)
    expect(MessageBuffer, :warn, fn "You can't go that way." -> :ok end)
    result = Move.dispatch("north", @state)
    assert result.ap == 9
    assert result.vicinity == @state.vicinity
  end
end
