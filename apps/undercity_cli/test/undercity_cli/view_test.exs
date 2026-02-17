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

  describe "render/3" do
    test "updates LiveScreen blocks without crashing" do
      View.render(@vicinity, @player)
    end

    test "accepts messages" do
      View.render(@vicinity, @player, [{"Hello", :info}])
    end
  end
end
