defmodule UndercityServer.Integration.JoinTest do
  use ExUnit.Case

  alias UndercityServer.Gateway
  alias UndercityServer.Vicinity

  describe "joining the world" do
    test "returns a Vicinity struct with expected shape" do
      %Vicinity{} = vicinity = Gateway.enter("Grimshaw_#{:rand.uniform(100_000)}")

      assert is_binary(vicinity.id)
      assert is_atom(vicinity.type)
      assert is_list(vicinity.people)
    end

    test "joining player appears in people list" do
      name = "Grimshaw_#{:rand.uniform(100_000)}"
      %Vicinity{} = vicinity = Gateway.enter(name)

      assert Enum.any?(vicinity.people, fn p -> p.name == name end)
    end

    test "reconnecting does not duplicate the player" do
      name = "Grimshaw_#{:rand.uniform(100_000)}"
      Gateway.enter(name)
      %Vicinity{} = vicinity = Gateway.enter(name)

      grimshaws = Enum.filter(vicinity.people, fn p -> p.name == name end)
      assert length(grimshaws) == 1
    end

    test "people list contains structs with name and id" do
      name = "Grimshaw_#{:rand.uniform(100_000)}"
      %Vicinity{} = vicinity = Gateway.enter(name)

      for person <- vicinity.people do
        assert is_binary(person.name)
        assert is_binary(person.id)
      end
    end
  end
end
