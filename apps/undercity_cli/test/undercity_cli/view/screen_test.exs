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

  describe "update_surroundings/1" do
    test "updates surroundings block" do
      Screen.init()
      Screen.update_surroundings(@vicinity)
    end
  end

  describe "update_description/2" do
    test "updates description block" do
      Screen.init()
      Screen.update_description(@vicinity, "Grimshaw")
    end
  end

  describe "update_messages/1" do
    test "updates messages block" do
      Screen.init()
      Screen.update_messages([{"Hello", :info}])
    end

    test "accepts empty messages" do
      Screen.init()
      Screen.update_messages([])
    end
  end
end
