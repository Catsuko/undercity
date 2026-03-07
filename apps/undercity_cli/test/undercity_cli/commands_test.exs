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
      expect(Gateway, :perform, fn _, _, :search, _ -> {:ok, :nothing, 9} end)
      expect(MessageBuffer, :warn, fn "You find nothing." -> :ok end)
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
      expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, "Sword", 9} end)
      expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)
      result = Commands.dispatch(%{@state | input: "drop 1"})
      assert result.ap == 9
    end

    test "routes eat with index to Eat" do
      expect(Gateway, :perform, fn @player_id, @block_id, :eat, 0 -> {:error, :invalid_index} end)
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Commands.dispatch(%{@state | input: "eat 1"}) == @state
    end

    test "routes scribble with text to Scribble" do
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello" -> {:error, :item_missing} end)
      expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
      assert Commands.dispatch(%{@state | input: "scribble hello"}) == @state
    end

    test "routes help to Help" do
      expect(MessageBuffer, :info, fn _ -> :ok end)
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
      expect(Gateway, :perform, fn @player_id, @block_id, :scribble, "hello world" -> {:error, :item_missing} end)
      expect(MessageBuffer, :warn, fn "You have no chalk." -> :ok end)
      assert Commands.dispatch(%{@state | input: "scribble hello world"}) == @state
    end

    test "drop with invalid index returns model unchanged with warning" do
      expect(MessageBuffer, :warn, fn "Invalid item selection." -> :ok end)
      assert Commands.dispatch(%{@state | input: "drop 0"}) == @state
    end
  end

  describe "pending re-dispatch" do
    test "routes single-stage pending to canonical execute clause" do
      expect(Gateway, :drop_item, fn @player_id, 2 -> {:ok, "Bread", 9} end)
      expect(MessageBuffer, :info, fn "You dropped Bread." -> :ok end)

      state = %{@state | pending: %{command: "drop", args: [2], label: "Drop which item?", choices: [], cursor: 0}}
      result = Commands.dispatch(state)

      assert result.ap == 9
      assert result.pending == nil
    end

    test "routes multi-stage pending to intermediate clause (attack target selected)" do
      target = %{id: "t1", name: "Zara"}
      items = [%{name: "Iron Pipe"}]
      expect(Gateway, :check_inventory, fn @player_id -> items end)

      vicinity = %Vicinity{id: @block_id, people: [target]}

      state = %{
        @state
        | vicinity: vicinity,
          pending: %{command: "attack", args: [0], label: "Attack who?", choices: [target], cursor: 0}
      }

      result = Commands.dispatch(state)

      assert result.pending.command == "attack"
      assert result.pending.args == ["Zara"]
      assert result.pending.label == "Attack with what?"
    end

    test "routes multi-stage pending to final execute clause (attack weapon selected)" do
      target = %{id: "t1", name: "Zara"}

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {"t1", 0, _} ->
        {:ok, {:hit, "t1", "Iron Pipe", 3}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 3 damage." -> :ok end)

      vicinity = %Vicinity{id: @block_id, people: [target]}

      state = %{
        @state
        | vicinity: vicinity,
          pending: %{command: "attack", args: ["Zara", 0], label: "Attack with what?", choices: [], cursor: 0}
      }

      result = Commands.dispatch(state)

      assert result.ap == 7
      assert result.pending == nil
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
