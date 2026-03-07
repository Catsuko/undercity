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

  describe "pending/3" do
    test "sets command and args when pending is nil" do
      state = State.pending(@state, "drop", [])
      assert state.pending == %{command: "drop", args: []}
    end

    test "sets args list with accumulated values" do
      state = State.pending(@state, "attack", ["Zara"])
      assert state.pending.args == ["Zara"]
    end

    test "merges into existing pending without clearing other keys" do
      state = %{@state | pending: %{label: "Pick one", choices: [], cursor: 0}}
      state = State.pending(state, "eat", [])
      assert state.pending.label == "Pick one"
      assert state.pending.command == "eat"
    end
  end

  describe "select/3" do
    test "adds label, choices, and cursor to pending" do
      items = ["Bread", "Potion"]
      state = @state |> State.pending("eat", []) |> State.select("Eat which item?", items)
      assert state.pending.label == "Eat which item?"
      assert state.pending.choices == items
      assert state.pending.cursor == 0
    end

    test "cursor always starts at 0" do
      state = @state |> State.pending("drop", []) |> State.select("Drop which item?", ["Sword"])
      assert state.pending.cursor == 0
    end
  end

  describe "clear_pending/1" do
    test "sets pending to nil" do
      state = @state |> State.pending("drop", []) |> State.clear_pending()
      assert state.pending == nil
    end

    test "is idempotent when pending is already nil" do
      assert State.clear_pending(@state).pending == nil
    end
  end

  describe "pending/3 then select/3 chained" do
    test "produces a fully-formed pending map with all required keys" do
      items = [%{name: "Iron Pipe"}]

      state =
        @state
        |> State.pending("attack", ["Zara"])
        |> State.select("Attack with what?", items)

      assert %{
               command: "attack",
               args: ["Zara"],
               label: "Attack with what?",
               choices: ^items,
               cursor: 0
             } = state.pending
    end
  end
end
