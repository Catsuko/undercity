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
    messages: [],
    gateway: Gateway,
    window_width: 80
  }

  test "bare scribble returns model unchanged with usage warning" do
    expect(MessageBuffer, :warn, fn "Usage: scribble <text>" -> :ok end)
    assert Scribble.dispatch("scribble", @state) == @state
  end

  test "scribble with text succeeds and returns model with updated ap" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "hello" -> {:ok, 9} end)
    expect(MessageBuffer, :success, fn "You scribble on the ground." -> :ok end)
    result = Scribble.dispatch({"scribble", "hello"}, @state)
    assert result.ap == 9
  end

  test "scribble with empty message returns model unchanged with success message" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "" -> {:error, :empty_message} end)
    expect(MessageBuffer, :success, fn "You scribble on the ground." -> :ok end)
    assert Scribble.dispatch({"scribble", ""}, @state) == @state
  end

  test "no chalk returns model unchanged with warning" do
    expect(Gateway, :perform, fn @player_id, _, :scribble, "hello" -> {:error, :item_missing} end)
    expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
    assert Scribble.dispatch({"scribble", "hello"}, @state) == @state
  end
end
