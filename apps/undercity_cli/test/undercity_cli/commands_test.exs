defmodule UndercityCli.CommandsTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands

  describe "routing" do
    test "routes all direction verbs to Move" do
      stub(Gateway, :perform, fn _, _, :move, _ -> {:ok, {:ok, %{id: "dest_block"}}, 9} end)

      for verb <- ~w(north south east west n s e w enter exit) do
        assert {:moved, new_state} = Commands.dispatch(verb, @state, Gateway, MessageBuffer)
        assert new_state.vicinity.id == "dest_block"
        assert new_state.ap == 9
      end
    end

    test "routes search to Search" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:ok, :nothing, 9} end)
      expect(MessageBuffer, :warn, fn "You find nothing." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("search", @state, Gateway, MessageBuffer)
      assert new_state.ap == 9
    end

    test "routes inventory to Inventory" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("inventory", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end

    test "routes i to Inventory" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
      assert {:continue, _} = Commands.dispatch("i", @state, Gateway, MessageBuffer)
    end

    test "routes drop with index to Drop" do
      expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, "Sword", 9} end)
      expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("drop 1", @state, Gateway, MessageBuffer)
      assert new_state.ap == 9
    end

    test "routes eat with index to Eat" do
      expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :invalid_index} end)
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("eat 1", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end

    test "routes scribble with text to Scribble" do
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello" -> {:error, :item_missing} end)
      expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("scribble hello", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end

    test "routes help to Help" do
      expect(MessageBuffer, :info, fn _ -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("help", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end

    test "warns and returns continue for unknown command" do
      expect(MessageBuffer, :warn, fn msg ->
        assert msg == "Unknown command. Type 'help' for a list of commands."
        :ok
      end)

      assert {:continue, new_state} = Commands.dispatch("fly", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end

    test "treats empty input as unknown" do
      expect(MessageBuffer, :warn, fn _ -> :ok end)
      assert {:continue, _} = Commands.dispatch("", @state, Gateway, MessageBuffer)
    end
  end

  describe "usage_hints/0" do
    test "returns a sorted newline-joined string of all command usages" do
      hints = Commands.usage_hints()
      assert is_binary(hints)
      lines = String.split(hints, "\n")
      assert lines == Enum.sort(lines)
      assert "help" in lines
      assert "search" in lines
    end
  end

  describe "input splitting" do
    test "scribble captures multi-word rest" do
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello world" -> {:error, :item_missing} end)
      expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
      assert {:continue, _} = Commands.dispatch("scribble hello world", @state, Gateway, MessageBuffer)
    end

    test "drop with invalid index returns continue with warning" do
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("drop 0", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end
  end

  describe "handle_action" do
    test "returns continue and warns when exhausted" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :exhausted} end)
      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("search", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end

    test "returns continue and warns when collapsed" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :collapsed} end)
      expect(MessageBuffer, :warn, fn "Your body has given out." -> :ok end)
      assert {:continue, new_state} = Commands.dispatch("search", @state, Gateway, MessageBuffer)
      assert new_state == @state
    end
  end
end
