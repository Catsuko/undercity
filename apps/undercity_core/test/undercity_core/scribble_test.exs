defmodule UndercityCore.ScribbleTest do
  use ExUnit.Case, async: true

  alias UndercityCore.Scribble

  describe "validate/1" do
    test "accepts valid alphanumeric text with spaces" do
      assert {:ok, "hello world"} = Scribble.validate("hello world")
    end

    test "accepts single character" do
      assert {:ok, "x"} = Scribble.validate("x")
    end

    test "accepts text at the 80 character limit" do
      text = String.duplicate("a", 80)
      assert {:ok, ^text} = Scribble.validate(text)
    end

    test "rejects text over 80 characters" do
      text = String.duplicate("a", 81)
      assert {:error, "scribble must be 80 characters or fewer"} = Scribble.validate(text)
    end

    test "rejects empty text" do
      assert {:error, "scribble cannot be empty"} = Scribble.validate("")
    end

    test "rejects special characters" do
      assert {:error, _} = Scribble.validate("hello!")
      assert {:error, _} = Scribble.validate("@#$")
      assert {:error, _} = Scribble.validate("hello\nworld")
    end

    test "accepts numbers" do
      assert {:ok, "room 42"} = Scribble.validate("room 42")
    end
  end
end
