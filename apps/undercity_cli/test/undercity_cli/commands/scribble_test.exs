defmodule UndercityCli.Commands.ScribbleTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Scribble

  @street_vicinity %Vicinity{type: :street}
  @state %State{
    player_id: @player_id,
    player_name: "player1",
    vicinity: @street_vicinity,
    ap: 10,
    hp: 10,
    input: "",
    message_log: [],
    gateway: Gateway,
    window_width: 80
  }

  test "bare scribble returns model unchanged with usage warning" do
    expect(MessageBuffer, :warn, fn "Usage: scribble <text>" -> :ok end)
    assert Scribble.dispatch("scribble", @state) == @state
  end

  test "scribble with text succeeds and returns model with updated ap" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "hello" -> {:ok, 9} end)
    result = Scribble.dispatch({"scribble", "hello"}, @state)
    assert result.ap == 9
  end

  test "empty message noop returns unchanged state" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "" -> {:ok, @state.ap} end)
    assert Scribble.dispatch({"scribble", ""}, @state) == @state
  end

  test "no chalk noop returns unchanged state" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "hello" -> {:ok, @state.ap} end)
    assert Scribble.dispatch({"scribble", "hello"}, @state) == @state
  end
end
