defmodule UndercityServer.Integration.JoinTest do
  use ExUnit.Case

  alias UndercityServer.Gateway

  describe "joining the world" do
    test "returns block info with expected shape" do
      block_info = Gateway.enter("Grimshaw_#{:rand.uniform(100_000)}")

      assert is_binary(block_info.id)
      assert is_atom(block_info.type)
      assert is_list(block_info.people)
    end

    test "joining player appears in people list" do
      name = "Grimshaw_#{:rand.uniform(100_000)}"
      block_info = Gateway.enter(name)

      assert Enum.any?(block_info.people, fn p -> p.name == name end)
    end

    test "reconnecting does not duplicate the player" do
      name = "Grimshaw_#{:rand.uniform(100_000)}"
      Gateway.enter(name)
      block_info = Gateway.enter(name)

      grimshaws = Enum.filter(block_info.people, fn p -> p.name == name end)
      assert length(grimshaws) == 1
    end

    test "people list contains structs with name and id" do
      name = "Grimshaw_#{:rand.uniform(100_000)}"
      block_info = Gateway.enter(name)

      for person <- block_info.people do
        assert is_binary(person.name)
        assert is_binary(person.id)
      end
    end
  end
end
