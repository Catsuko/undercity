defmodule UndercityServer.Integration.JoinTest do
  use ExUnit.Case

  alias UndercityServer.GameServer

  setup do
    name = "test_server_#{:rand.uniform(100_000)}"
    {:ok, pid} = GameServer.start_link(name: name)
    %{pid: pid}
  end

  describe "joining the world" do
    test "returns block info with expected shape", %{pid: pid} do
      assert {:ok, block_info} = GenServer.call(pid, {:connect, "Grimshaw"})

      assert is_binary(block_info.id)
      assert is_binary(block_info.name)
      assert is_atom(block_info.type)
      assert is_list(block_info.people)
    end

    test "joining player appears in people list", %{pid: pid} do
      {:ok, block_info} = GenServer.call(pid, {:connect, "Grimshaw"})

      assert Enum.any?(block_info.people, fn p -> p.name == "Grimshaw" end)
    end

    test "reconnecting does not duplicate the player", %{pid: pid} do
      GenServer.call(pid, {:connect, "Grimshaw"})
      {:ok, block_info} = GenServer.call(pid, {:connect, "Grimshaw"})

      grimshaws = Enum.filter(block_info.people, fn p -> p.name == "Grimshaw" end)
      assert length(grimshaws) == 1
    end

    test "people list contains structs with name and id", %{pid: pid} do
      {:ok, block_info} = GenServer.call(pid, {:connect, "Grimshaw"})

      for person <- block_info.people do
        assert is_binary(person.name)
        assert is_binary(person.id)
      end
    end
  end
end
