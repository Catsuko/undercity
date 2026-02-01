defmodule UndercityCore.ServerTest do
  use ExUnit.Case

  alias UndercityCore.Server

  setup do
    name = "test_server_#{:rand.uniform(10000)}"
    {:ok, pid} = Server.start_link(name: name)
    %{name: name, pid: pid}
  end

  test "start_link registers server globally", %{name: name} do
    assert is_pid(:global.whereis_name({UndercityCore.Server, name}))
  end

  test "connect returns server name", %{name: name} do
    assert {:ok, ^name} = Server.connect(name, "player")
  end

  test "connect with non-existent server returns error" do
    assert {:error, :server_not_found} = Server.connect("nonexistent", "player")
  end

  test "multiple servers can run with different names" do
    other_name = "other_server_#{:rand.uniform(10000)}"
    {:ok, _pid} = Server.start_link(name: other_name)

    assert {:ok, _} = Server.connect(other_name, "player")
  end
end
