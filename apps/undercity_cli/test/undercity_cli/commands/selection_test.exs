defmodule UndercityCli.Commands.SelectionTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands.Selection

  @items [%{name: "Sword"}, %{name: "Bread"}]

  describe "from_list/6" do
    test "warns and returns state unchanged when list is empty" do
      expect(MessageBuffer, :warn, fn "Nothing here." -> :ok end)
      assert Selection.from_list(@state, [], "drop", [], "Nothing here.", "Drop what?") == @state
    end

    test "warns and returns state unchanged when list is nil" do
      expect(MessageBuffer, :warn, fn "Nothing here." -> :ok end)
      assert Selection.from_list(@state, nil, "drop", [], "Nothing here.", "Drop what?") == @state
    end

    test "opens a selection overlay with the given label and choices" do
      state = Selection.from_list(@state, @items, "drop", [], "Nothing here.", "Drop what?")
      assert state.selection.label == "Drop what?"
      assert state.selection.choices == @items
      assert state.selection.cursor == 0
    end

    test "on_confirm dispatches to the command with cursor appended to args" do
      expect(Gateway, :drop_item, fn @player_id, 0 -> {:ok, "Sword", 9} end)
      expect(MessageBuffer, :info, fn "You dropped Sword." -> :ok end)

      state = Selection.from_list(@state, @items, "drop", [], "Nothing here.", "Drop what?")
      result = state.selection.on_confirm.(state)

      assert result.ap == 9
      assert result.selection == nil
    end

    test "on_confirm with accumulated args dispatches multi-stage command" do
      target = %{id: "t1", name: "Zara"}
      vicinity = %Vicinity{id: @block_id, people: [target]}
      state = %{@state | vicinity: vicinity}

      expect(Gateway, :perform, fn @player_id, @block_id, :attack, {"t1", 0, _} ->
        {:ok, {:hit, "t1", "Iron Pipe", 3}, 7}
      end)

      expect(MessageBuffer, :success, fn "You attack Zara with Iron Pipe and do 3 damage." -> :ok end)

      state = Selection.from_list(state, @items, "attack", ["Zara"], "Nothing here.", "Attack with what?")
      result = state.selection.on_confirm.(state)

      assert result.ap == 7
      assert result.selection == nil
    end

    test "on_cancel clears selection" do
      state = Selection.from_list(@state, @items, "drop", [], "Nothing here.", "Drop what?")
      result = state.selection.on_cancel.(state)
      assert result.selection == nil
    end
  end
end
