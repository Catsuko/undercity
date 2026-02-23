defmodule UndercityCli.Commands.ScribbleTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Scribble

  @street_vicinity %UndercityServer.Vicinity{type: :street}
  @state %GameState{player_id: @player_id, vicinity: @street_vicinity, ap: 10, hp: 10}

  test "bare scribble returns continue with usage warning and unchanged state" do
    expect(MessageBuffer, :warn, fn "Usage: scribble <text>" -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch("scribble", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "scribble with text succeeds and returns continue with success message and updated ap" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "hello" -> {:ok, 9} end)
    expect(MessageBuffer, :success, fn "You scribble on the ground." -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch({"scribble", "hello"}, @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "scribble with empty message returns continue with success message and unchanged state" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "" -> {:error, :empty_message} end)
    expect(MessageBuffer, :success, fn "You scribble on the ground." -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch({"scribble", ""}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "no chalk returns continue with warning and unchanged state" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "hello" -> {:error, :item_missing} end)
    expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch({"scribble", "hello"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
