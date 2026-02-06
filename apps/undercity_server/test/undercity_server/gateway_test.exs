defmodule UndercityServer.GatewayTest do
  use ExUnit.Case

  alias UndercityServer.Gateway

  describe "enter/1" do
    test "creates a person and spawns them in the plaza" do
      info = Gateway.enter("Grimshaw")

      assert info.id == "plaza"
      assert info.name == "The Plaza"
      assert info.description == "The central gathering place of the undercity."
      assert Enum.any?(info.people, fn p -> p.name == "Grimshaw" end)
    end

    test "multiple people can enter" do
      Gateway.enter("Grimshaw")
      info = Gateway.enter("Mordecai")

      names = Enum.map(info.people, & &1.name)
      assert "Grimshaw" in names
      assert "Mordecai" in names
    end
  end
end
