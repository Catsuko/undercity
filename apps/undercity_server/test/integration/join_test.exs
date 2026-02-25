defmodule UndercityServer.Integration.JoinTest do
  use ExUnit.Case

  alias UndercityServer.Test.Helpers
  alias UndercityServer.Vicinity

  describe "joining the world" do
    test "returns a player id and Vicinity struct with expected shape" do
      {player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(Helpers.player_name())

      assert is_binary(player_id)
      assert is_binary(vicinity.id)
      assert is_atom(vicinity.type)
      assert is_list(vicinity.people)
    end

    test "joining player appears in people list" do
      name = Helpers.player_name()
      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "reconnecting does not duplicate the player" do
      name = Helpers.player_name()
      Helpers.enter_player!(name)
      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      grimshaws = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(grimshaws) == 1
    end

    test "people list contains maps with name and id" do
      name = Helpers.player_name()
      {_player_id, %Vicinity{} = vicinity, _constitution} = Helpers.enter_player!(name)

      for person <- vicinity.people do
        assert is_binary(person.name)
        assert is_binary(person.id)
      end
    end
  end
end
