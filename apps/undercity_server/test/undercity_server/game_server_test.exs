defmodule UndercityServer.GameServerTest do
  use ExUnit.Case

  alias UndercityServer.GameServer

  setup do
    name = "test_server_#{:rand.uniform(10000)}"
    {:ok, pid} = GameServer.start_link(name: name)
    %{name: name, pid: pid}
  end

  test "start_link registers server in local registry", %{name: name} do
    assert [{pid, _}] = Registry.lookup(UndercityServer.GameServer.Registry, name)
    assert is_pid(pid)
  end

  test "connect returns server name", %{name: name} do
    assert {:ok, ^name} = GameServer.connect(name, "player")
  end

  test "connect with non-existent server returns error" do
    assert {:error, :server_not_found} = GameServer.connect("nonexistent", "player")
  end

  test "multiple servers can run with different names" do
    other_name = "other_server_#{:rand.uniform(10000)}"
    {:ok, _pid} = GameServer.start_link(name: other_name)

    assert {:ok, _} = GameServer.connect(other_name, "player")
  end
end
