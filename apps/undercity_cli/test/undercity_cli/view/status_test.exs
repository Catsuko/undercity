defmodule UndercityCli.View.StatusTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View.Status

  defp render_to_string(data), do: data |> Owl.Data.to_chardata() |> IO.iodata_to_binary()

  describe "format_message/2" do
    test "formats info message with icon" do
      result = "You find nothing." |> Status.format_message() |> render_to_string()

      assert result =~ "▸ You find nothing."
      assert result =~ "\e[38;5;67m"
    end

    test "formats success message in green" do
      result = "You found Junk!" |> Status.format_message(:success) |> render_to_string()

      assert result =~ "▸ You found Junk!"
      assert result =~ "\e[38;5;108m"
    end

    test "formats warning message in red" do
      result = "You can't go that way." |> Status.format_message(:warning) |> render_to_string()

      assert result =~ "▸ You can't go that way."
      assert result =~ "\e[38;5;131m"
    end

    test "defaults to info category" do
      result = "Some message." |> Status.format_message() |> render_to_string()

      assert result =~ "\e[38;5;67m"
    end
  end
end
