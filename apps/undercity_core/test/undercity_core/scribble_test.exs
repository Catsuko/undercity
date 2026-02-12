defmodule UndercityCore.ScribbleTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Scribble

  describe "sanitise/1" do
    test "passes through valid alphanumeric text with spaces" do
      assert {:ok, "hello world"} = Scribble.sanitise("hello world")
    end

    test "strips invalid characters" do
      assert {:ok, "hello world"} = Scribble.sanitise("hello! @world#")
    end

    test "returns :empty for text with only invalid characters" do
      assert :empty = Scribble.sanitise("@#$!")
    end

    test "returns :empty for empty string" do
      assert :empty = Scribble.sanitise("")
    end

    test "returns :empty for whitespace only" do
      assert :empty = Scribble.sanitise("   ")
    end

    test "trims leading and trailing whitespace" do
      assert {:ok, "hello"} = Scribble.sanitise("  hello  ")
    end

    test "truncates to 80 characters" do
      long = String.duplicate("a", 100)
      assert {:ok, truncated} = Scribble.sanitise(long)
      assert String.length(truncated) == 80
    end

    test "accepts numbers" do
      assert {:ok, "room 42"} = Scribble.sanitise("room 42")
    end
  end
end
