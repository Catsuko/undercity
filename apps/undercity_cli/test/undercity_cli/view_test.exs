defmodule UndercityCli.ViewTest do
  use ExUnit.Case, async: true

  alias UndercityCli.View
  alias UndercityServer.Vicinity

  @vicinity %Vicinity{
    id: "plaza",
    type: :square,
    people: [],
    neighbourhood: [[nil, nil, nil], [nil, "plaza", nil], [nil, nil, nil]],
    building_type: nil
  }

  @player "Grimshaw"

  describe "render_surroundings/1" do
    test "updates surroundings block without crashing" do
      View.render_surroundings(@vicinity)
    end
  end

  describe "render_description/2" do
    test "updates description block without crashing" do
      View.render_description(@vicinity, @player)
    end
  end

  describe "render_messages/1" do
    test "updates messages block without crashing" do
      View.render_messages([{"Hello", :info}])
    end

    test "accepts empty messages" do
      View.render_messages([])
    end
  end
end
