defmodule UndercityCli.StateTest do
  use ExUnit.Case, async: true

  alias UndercityCli.State

  @state %State{
    player_id: "p1",
    player_name: "p1",
    vicinity: nil,
    ap: 10,
    hp: 10,
    input: "",
    message_log: [],
    gateway: nil,
    window_width: 80
  }

  describe "clear_selection/1" do
    test "sets selection to nil" do
      state = %{@state | selection: %{label: "Pick one"}}
      assert State.clear_selection(state).selection == nil
    end

    test "is idempotent when selection is already nil" do
      assert State.clear_selection(@state).selection == nil
    end
  end
end
