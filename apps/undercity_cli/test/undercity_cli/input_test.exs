defmodule UndercityCli.InputTest do
  use ExUnit.Case, async: true

  alias UndercityCli.Input

  defp device(string) do
    {:ok, device} = StringIO.open(string)
    device
  end

  describe "gets/1" do
    test "returns the input string" do
      assert Input.gets(device("north\n")) == "north"
    end

    test "trims leading and trailing whitespace" do
      assert Input.gets(device("  north  \n")) == "north"
    end

    test "downcases the input" do
      assert Input.gets(device("NORTH\n")) == "north"
    end

    test "trims and downcases together" do
      assert Input.gets(device("  Go North  \n")) == "go north"
    end

    test "returns empty string for blank input" do
      assert Input.gets(device("\n")) == ""
    end
  end
end
