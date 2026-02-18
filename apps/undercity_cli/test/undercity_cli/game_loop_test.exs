defmodule UndercityCli.GameLoopTest do
  use ExUnit.Case, async: true

  alias UndercityCli.GameLoop

  describe "parse/1" do
    test "parses quit commands" do
      assert GameLoop.parse("quit") == :quit
      assert GameLoop.parse("q") == :quit
    end

    test "parses full direction names" do
      assert GameLoop.parse("north") == {:move, :north}
      assert GameLoop.parse("south") == {:move, :south}
      assert GameLoop.parse("east") == {:move, :east}
      assert GameLoop.parse("west") == {:move, :west}
    end

    test "parses short direction names" do
      assert GameLoop.parse("n") == {:move, :north}
      assert GameLoop.parse("s") == {:move, :south}
      assert GameLoop.parse("e") == {:move, :east}
      assert GameLoop.parse("w") == {:move, :west}
    end

    test "parses enter and exit commands" do
      assert GameLoop.parse("enter") == {:move, :enter}
      assert GameLoop.parse("exit") == {:move, :exit}
    end

    test "parses scribble command with text" do
      assert GameLoop.parse("scribble hello world") == {:scribble, "hello world"}
    end

    test "parses eat command with index" do
      assert GameLoop.parse("eat 1") == {:eat, 0}
      assert GameLoop.parse("eat 3") == {:eat, 2}
    end

    test "eat with invalid index returns unknown" do
      assert GameLoop.parse("eat 0") == :unknown
      assert GameLoop.parse("eat -1") == :unknown
      assert GameLoop.parse("eat abc") == :unknown
      assert GameLoop.parse("eat") == :unknown
    end

    test "returns unknown for unrecognized input" do
      assert GameLoop.parse("fly") == :unknown
      assert GameLoop.parse("dance") == :unknown
      assert GameLoop.parse("") == :unknown
    end
  end
end
