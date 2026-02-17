defmodule UndercityCli.View.StatusTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias UndercityCli.View.Status

  describe "format_message/2" do
    test "formats info message with icon" do
      result = Status.format_message("You find nothing.")

      assert result =~ "▸ You find nothing."
      assert result =~ "\e[38;5;67m"
    end

    test "formats success message in green" do
      result = Status.format_message("You found Junk!", :success)

      assert result =~ "▸ You found Junk!"
      assert result =~ "\e[38;5;108m"
    end

    test "formats warning message in red" do
      result = Status.format_message("You can't go that way.", :warning)

      assert result =~ "▸ You can't go that way."
      assert result =~ "\e[38;5;131m"
    end
  end

  describe "render_message/1" do
    test "prints formatted message for tuple" do
      output = capture_io(fn -> Status.render_message({"hello", :info}) end)

      assert output =~ "▸ hello"
    end

    test "does nothing for nil" do
      output = capture_io(fn -> Status.render_message(nil) end)

      assert output == ""
    end
  end
end
