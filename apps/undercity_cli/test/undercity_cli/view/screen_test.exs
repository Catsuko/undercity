defmodule UndercityCli.View.ScreenTest do
  use ExUnit.Case

  alias UndercityCli.View.Screen
  alias UndercityServer.Vicinity

  @vicinity %Vicinity{
    id: "plaza",
    type: :square,
    people: [],
    neighbourhood: [[nil, nil, nil], [nil, "plaza", nil], [nil, nil, nil]],
    building_type: nil
  }

  describe "init/0" do
    test "registers blocks with LiveScreen" do
      Screen.init()
    end
  end

  describe "update/3" do
    test "updates all blocks" do
      Screen.init()
      Screen.update(@vicinity, "Grimshaw", [{"Hello", :info}])
    end

    test "defaults to empty messages" do
      Screen.init()
      Screen.update(@vicinity, "Grimshaw")
    end
  end
end
