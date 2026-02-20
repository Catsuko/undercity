defmodule UndercityCli.CommandsTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Commands
  alias UndercityCli.GameState

  @state %GameState{player_id: "player1", vicinity: %{id: "block1"}, ap: 10, hp: 10}

  describe "routing" do
    test "routes all direction verbs to Move" do
      for verb <- ~w(north south east west n s e w enter exit) do
        assert {:moved, new_state} = Commands.dispatch(verb, @state, FakeGateway, FakeMessageBuffer)
        assert new_state.vicinity.id == "dest_block"
        assert new_state.ap == 9
      end
    end

    test "routes search to Search" do
      assert {:continue, new_state} = Commands.dispatch("search", @state, FakeGateway, FakeMessageBuffer)
      assert new_state.ap == 9
      assert_received {:warn, "You find nothing."}
    end

    test "routes inventory to Inventory" do
      assert {:continue, new_state} = Commands.dispatch("inventory", @state, FakeGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:info, "Your inventory is empty."}
    end

    test "routes i to Inventory" do
      assert {:continue, _} = Commands.dispatch("i", @state, FakeGateway, FakeMessageBuffer)
      assert_received {:info, "Your inventory is empty."}
    end

    test "routes drop with index to Drop" do
      assert {:continue, new_state} = Commands.dispatch("drop 1", @state, FakeGateway, FakeMessageBuffer)
      assert new_state.ap == 9
      assert_received {:info, "You dropped Sword."}
    end

    test "routes eat with index to Eat" do
      assert {:continue, new_state} = Commands.dispatch("eat 1", @state, FakeGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:warn, "Invalid item selection."}
    end

    test "routes scribble with text to Scribble" do
      assert {:continue, new_state} = Commands.dispatch("scribble hello", @state, FakeGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:warn, "You have no chalk."}
    end

    test "warns and returns continue for unknown command" do
      assert {:continue, new_state} = Commands.dispatch("fly", @state, FakeGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:warn, msg}
      assert msg =~ "Unknown command"
    end

    test "treats empty input as unknown" do
      assert {:continue, _} = Commands.dispatch("", @state, FakeGateway, FakeMessageBuffer)
      assert_received {:warn, _}
    end
  end

  describe "input splitting" do
    test "scribble captures multi-word rest" do
      assert {:continue, _} = Commands.dispatch("scribble hello world", @state, FakeGateway, FakeMessageBuffer)
      assert_received {:warn, "You have no chalk."}
    end

    test "drop with invalid index returns continue with warning" do
      assert {:continue, new_state} = Commands.dispatch("drop 0", @state, FakeGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:warn, "Invalid item selection."}
    end
  end

  describe "handle_action" do
    test "returns continue and warns when exhausted" do
      assert {:continue, new_state} = Commands.dispatch("search", @state, ExhaustedGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:warn, "You are too exhausted to act."}
    end

    test "returns continue and warns when collapsed" do
      assert {:continue, new_state} = Commands.dispatch("search", @state, CollapsedGateway, FakeMessageBuffer)
      assert new_state == @state
      assert_received {:warn, "Your body has given out."}
    end
  end
end
