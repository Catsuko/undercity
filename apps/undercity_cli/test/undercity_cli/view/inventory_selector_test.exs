defmodule UndercityCli.View.InventorySelectorTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.InventorySelector

  describe "parse_choice/2" do
    test "accepts valid numbers within range" do
      assert InventorySelector.parse_choice("1", 3) == {:ok, 1}
      assert InventorySelector.parse_choice("3", 3) == {:ok, 3}
    end

    test "trims whitespace before parsing" do
      assert InventorySelector.parse_choice("  2  ", 3) == {:ok, 2}
    end

    test "rejects zero and negative numbers" do
      assert InventorySelector.parse_choice("0", 3) == :error
      assert InventorySelector.parse_choice("-1", 3) == :error
    end

    test "rejects numbers out of range" do
      assert InventorySelector.parse_choice("4", 3) == :error
    end

    test "rejects non-numeric input" do
      assert InventorySelector.parse_choice("abc", 3) == :error
      assert InventorySelector.parse_choice("", 3) == :error
    end

    test "rejects non-binary input" do
      assert InventorySelector.parse_choice(:eof, 3) == :error
      assert InventorySelector.parse_choice(nil, 3) == :error
    end
  end
end
