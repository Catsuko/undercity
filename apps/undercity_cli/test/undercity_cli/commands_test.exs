defmodule UndercityCli.CommandsTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands

  describe "routing" do
    test "routes all direction verbs to Move" do
      stub(Gateway, :perform, fn _, _, :move, _ -> {:ok, {:ok, %{id: "dest_block"}}, 9} end)

      for verb <- ~w(north south east west n s e w enter exit) do
        result = Commands.dispatch(verb, @state)
        assert result.vicinity.id == "dest_block"
        assert result.ap == 9
      end
    end

    test "routes search to Search" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:ok, :nothing, 9} end)
      expect(MessageBuffer, :warn, fn "You find nothing." -> :ok end)
      result = Commands.dispatch("search", @state)
      assert result.ap == 9
    end

    test "routes inventory to Inventory" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
      assert Commands.dispatch("inventory", @state) == @state
    end

    test "routes i to Inventory" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
      assert Commands.dispatch("i", @state) == @state
    end

    test "routes drop with index to Drop" do
      expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, "Sword", 9} end)
      expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
      result = Commands.dispatch("drop 1", @state)
      assert result.ap == 9
    end

    test "routes eat with index to Eat" do
      expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :invalid_index} end)
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Commands.dispatch("eat 1", @state) == @state
    end

    test "routes scribble with text to Scribble" do
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello" -> {:error, :item_missing} end)
      expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
      assert Commands.dispatch("scribble hello", @state) == @state
    end

    test "routes help to Help" do
      expect(MessageBuffer, :info, fn _ -> :ok end)
      assert Commands.dispatch("help", @state) == @state
    end

    test "warns and returns model unchanged for unknown command" do
      expect(MessageBuffer, :warn, fn msg ->
        assert msg == "Unknown command. Type 'help' for a list of commands."
        :ok
      end)

      assert Commands.dispatch("fly", @state) == @state
    end

    test "treats empty input as unknown" do
      expect(MessageBuffer, :warn, fn _ -> :ok end)
      assert Commands.dispatch("", @state) == @state
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
      assert Commands.dispatch("scribble hello world", @state) == @state
    end

    test "drop with invalid index returns model unchanged with warning" do
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Commands.dispatch("drop 0", @state) == @state
    end
  end

  describe "handle_action" do
    test "warns and returns model unchanged when exhausted" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :exhausted} end)
      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)
      assert Commands.dispatch("search", @state) == @state
    end

    test "warns and returns model unchanged when collapsed" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :collapsed} end)
      expect(MessageBuffer, :warn, fn "Your body has given out." -> :ok end)
      assert Commands.dispatch("search", @state) == @state
    end
  end
end
