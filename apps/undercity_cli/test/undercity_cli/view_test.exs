defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias UndercityCli.View
  alias UndercityServer.Vicinity

  describe "render/2" do
    test "renders surroundings and block description" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [%{id: "1", name: "Grimshaw"}, %{id: "2", name: "Mordecai"}],
        neighbourhood: [
          ["ashwell", "north_alley", "wormgarden"],
          ["west_street", "plaza", "east_street"],
          ["the_stray", "south_alley", "lame_horse"]
        ],
        building_type: nil
      }

      output = capture_io(fn -> View.render(vicinity, "Grimshaw") end)

      # Grid
      assert output =~ "┌"
      assert output =~ "The Plaza"
      # Description
      assert output =~ "You are at"
      assert output =~ "A wide, open space"
      # People
      assert output =~ "Mordecai"
    end

    test "clears screen before rendering" do
      vicinity = %Vicinity{
        id: "plaza",
        type: :square,
        people: [],
        neighbourhood: [[nil, nil, nil], [nil, "plaza", nil], [nil, nil, nil]],
        building_type: nil
      }

      output = capture_io(fn -> View.render(vicinity, "Grimshaw") end)

      assert output =~ "\e[2J"
    end
  end

  describe "render_message/1" do
    test "prints formatted message" do
      output = capture_io(fn -> View.render_message({"You found Junk!", :success}) end)

      assert output =~ "▸ You found Junk!"
    end

    test "does nothing for nil" do
      output = capture_io(fn -> View.render_message(nil) end)

      assert output == ""
    end
  end
end
