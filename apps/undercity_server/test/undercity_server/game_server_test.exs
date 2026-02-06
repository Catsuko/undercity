defmodule UndercityServer.GameServerTest do
  use ExUnit.Case

  alias UndercityServer.GameServer

  setup do
    name = "test_server_#{:rand.uniform(10000)}"
    {:ok, pid} = GameServer.start_link(name: name)
    %{name: name, pid: pid}
  end

  test "start_link registers server in global registry", %{name: name} do
    pid = :global.whereis_name(name)
    assert is_pid(pid)
  end

  test "handle_call :connect returns block name", %{pid: pid} do
    assert {:ok, "The Plaza"} = GenServer.call(pid, {:connect, "player"})
  end

  test "multiple servers can run with different names" do
    other_name = "other_server_#{:rand.uniform(10000)}"
    {:ok, pid} = GameServer.start_link(name: other_name)

    assert {:ok, "The Plaza"} = GenServer.call(pid, {:connect, "player"})
  end
end
