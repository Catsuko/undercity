defmodule ScribbleSuccessGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :scribble, _text), do: {:ok, 9}
end

defmodule ScribbleEmptyMessageGateway do
  @moduledoc false
  def perform(_player_id, _block_id, :scribble, _text), do: {:error, :empty_message}
end

defmodule UndercityCli.Commands.ScribbleTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands.Scribble
  alias UndercityCli.GameState

  @street_vicinity %UndercityServer.Vicinity{type: :street}
  @state %GameState{player_id: "player1", vicinity: @street_vicinity, ap: 10, hp: 10}

  test "bare scribble returns continue with usage warning and unchanged state" do
    assert {:continue, new_state} = Scribble.dispatch("scribble", @state, FakeGateway, FakeMessageBuffer)
    assert new_state == @state
    assert_received {:warn, "Usage: scribble <text>"}
  end

  test "scribble with text succeeds and returns continue with success message and updated ap" do
    assert {:continue, new_state} =
             Scribble.dispatch({"scribble", "hello"}, @state, ScribbleSuccessGateway, FakeMessageBuffer)

    assert new_state.ap == 9
    assert_received {:success, "You scribble on the ground."}
  end

  test "scribble with empty message returns continue with success message and unchanged state" do
    assert {:continue, new_state} =
             Scribble.dispatch({"scribble", ""}, @state, ScribbleEmptyMessageGateway, FakeMessageBuffer)

    assert new_state == @state
    assert_received {:success, "You scribble on the ground."}
  end

  test "no chalk returns continue with warning and unchanged state" do
    assert {:continue, new_state} =
             Scribble.dispatch({"scribble", "hello"}, @state, FakeGateway, FakeMessageBuffer)

    assert new_state == @state
    assert_received {:warn, "You have no chalk."}
  end
end
