defmodule UndercityCli.View.SelectionTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.Selection

  @choices [%{name: "Sword"}, %{name: "Potion"}, %{name: "Bread"}]
  @selection %Selection{label: "Pick one", choices: @choices, cursor: 1, on_confirm: nil, on_cancel: nil}

  describe "move_up/1" do
    test "decrements cursor by one" do
      assert Selection.move_up(@selection).cursor == 0
    end

    test "clamps at zero" do
      selection = %{@selection | cursor: 0}
      assert Selection.move_up(selection).cursor == 0
    end
  end

  describe "move_down/1" do
    test "increments cursor by one" do
      assert Selection.move_down(@selection).cursor == 2
    end

    test "clamps at last choice index" do
      selection = %{@selection | cursor: 2}
      assert Selection.move_down(selection).cursor == 2
    end
  end

  describe "confirm/2" do
    test "calls on_confirm with state" do
      selection = %{@selection | on_confirm: fn state -> Map.put(state, :confirmed, true) end}
      result = Selection.confirm(selection, %{})
      assert result.confirmed == true
    end
  end

  describe "cancel/2" do
    test "calls on_cancel with state" do
      selection = %{@selection | on_cancel: fn state -> Map.put(state, :cancelled, true) end}
      result = Selection.cancel(selection, %{})
      assert result.cancelled == true
    end
  end
end
