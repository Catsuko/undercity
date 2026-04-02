defmodule UndercityCli.CommandsTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands

  describe "routing" do
    test "routes all direction verbs to Move" do
      stub(Gateway, :perform, fn _, _, :move, _ -> {:ok, {:ok, %Vicinity{id: "dest_block"}}, 9} end)
      stub(MessageBuffer, :info, fn _ -> :ok end)

      for verb <- ~w(north south east west n s e w enter exit) do
        result = Commands.dispatch(%{@state | input: verb})
        assert result.vicinity.id == "dest_block"
        assert result.ap == 9
      end
    end

    test "routes search to Search" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:ok, 9} end)
      result = Commands.dispatch(%{@state | input: "search"})
      assert result.ap == 9
    end

    test "routes inventory to Inventory" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
      assert Commands.dispatch(%{@state | input: "inventory"}) == @state
    end

    test "routes i to Inventory" do
      expect(Gateway, :check_inventory, fn @player_id -> [] end)
      expect(MessageBuffer, :info, fn "Your inventory is empty." -> :ok end)
      assert Commands.dispatch(%{@state | input: "i"}) == @state
    end

    test "routes drop with index to Drop" do
      expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, 9} end)
      result = Commands.dispatch(%{@state | input: "drop 1"})
      assert result.ap == 9
    end

    test "routes eat with index to Eat" do
      expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:ok, 9, 11} end)
      result = Commands.dispatch(%{@state | input: "eat 1"})
      assert result.ap == 9
      assert result.hp == 11
    end

    test "routes scribble with text to Scribble" do
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello" -> {:ok, 10} end)
      assert Commands.dispatch(%{@state | input: "scribble hello"}) == @state
    end

    test "routes help to Help" do
      stub(MessageBuffer, :info, fn _ -> :ok end)
      assert Commands.dispatch(%{@state | input: "help"}) == @state
    end

    test "warns and returns model unchanged for unknown command" do
      expect(MessageBuffer, :warn, fn msg ->
        assert msg == "Unknown command. Type 'help' for a list of commands."
        :ok
      end)

      assert Commands.dispatch(%{@state | input: "fly"}) == @state
    end

    test "treats empty input as unknown" do
      expect(MessageBuffer, :warn, fn _ -> :ok end)
      assert Commands.dispatch(%{@state | input: ""}) == @state
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
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello world" -> {:ok, 10} end)
      assert Commands.dispatch(%{@state | input: "scribble hello world"}) == @state
    end

    test "drop with invalid index returns model unchanged with warning" do
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Commands.dispatch(%{@state | input: "drop 0"}) == @state
    end
  end

  describe "handle_action" do
    test "warns and returns model unchanged when exhausted" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :exhausted} end)
      expect(MessageBuffer, :warn, fn "You are too exhausted to act." -> :ok end)
      assert Commands.dispatch(%{@state | input: "search"}) == @state
    end

    test "warns and returns model unchanged when collapsed" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :collapsed} end)
      expect(MessageBuffer, :warn, fn "Your body has given out." -> :ok end)
      assert Commands.dispatch(%{@state | input: "search"}) == @state
    end

    test "warns and returns model unchanged when not in block" do
      expect(Gateway, :perform, fn _, _, :search, _ -> {:error, :not_in_block} end)
      expect(MessageBuffer, :warn, fn "You can't do that from here." -> :ok end)
      assert Commands.dispatch(%{@state | input: "search"}) == @state
    end
  end
end
