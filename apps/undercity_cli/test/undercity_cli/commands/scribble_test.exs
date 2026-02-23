defmodule UndercityCli.Commands.ScribbleTest do
  use ExUnit.Case, async: true
  use Mimic

  alias UndercityCli.Commands.Scribble
  alias UndercityCli.GameState
  alias UndercityCli.MessageBuffer
  alias UndercityServer.Gateway

  @street_vicinity %UndercityServer.Vicinity{type: :street}
  @state %GameState{player_id: "player1", vicinity: @street_vicinity, ap: 10, hp: 10}

  test "bare scribble returns continue with usage warning and unchanged state" do
    expect(MessageBuffer, :warn, fn "Usage: scribble <text>" -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch("scribble", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "scribble with text succeeds and returns continue with success message and updated ap" do
    expect(Gateway, :perform, fn "player1", _, :scribble, "hello" -> {:ok, 9} end)
    expect(MessageBuffer, :success, fn "You scribble on the ground." -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch({"scribble", "hello"}, @state, Gateway, MessageBuffer)
    assert new_state.ap == 9
  end

  test "scribble with empty message returns continue with success message and unchanged state" do
    expect(Gateway, :perform, fn "player1", _, :scribble, "" -> {:error, :empty_message} end)
    expect(MessageBuffer, :success, fn "You scribble on the ground." -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch({"scribble", ""}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end

  test "no chalk returns continue with warning and unchanged state" do
    expect(Gateway, :perform, fn "player1", _, :scribble, "hello" -> {:error, :item_missing} end)
    expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
    assert {:continue, new_state} = Scribble.dispatch({"scribble", "hello"}, @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
