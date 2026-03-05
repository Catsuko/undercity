defmodule UndercityCli.View.StatusTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.Status

  describe "format_message/2" do
    test "formats info message with icon" do
      element = Status.format_message("You find nothing.")

      assert element.attributes.content == "▸ You find nothing."
      assert element.attributes.color == Ratatouille.Constants.color(:blue)
    end

    test "formats success message in green" do
      element = Status.format_message("You found Junk!", :success)

      assert element.attributes.content == "▸ You found Junk!"
      assert element.attributes.color == Ratatouille.Constants.color(:green)
    end

    test "formats warning message in red" do
      element = Status.format_message("You can't go that way.", :warning)

      assert element.attributes.content == "▸ You can't go that way."
      assert element.attributes.color == Ratatouille.Constants.color(:red)
    end

    test "defaults to info category" do
      element = Status.format_message("Some message.")

      assert element.attributes.color == Ratatouille.Constants.color(:blue)
    end
  end
end
