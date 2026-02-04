defmodule UndercityServer.GameServer do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: {:via, Registry, {__MODULE__.Registry, name}})
  end

  def connect(server_name, player_name) do
    case Registry.lookup(__MODULE__.Registry, server_name) do
      [{_pid, _}] ->
        local_connect(server_name, player_name)

      [] ->
        server_node = UndercityServer.server_node()
        Node.connect(server_node)
        rpc_connect(server_node, server_name, player_name)
    end
  end

  defp local_connect(server_name, player_name) do
    GenServer.call({:via, Registry, {__MODULE__.Registry, server_name}}, {:connect, player_name})
  catch
    :exit, _ -> {:error, :server_not_found}
  end

  defp rpc_connect(server_node, server_name, player_name) do
    case :rpc.call(server_node, GenServer, :call, [
           {:via, Registry, {__MODULE__.Registry, server_name}},
           {:connect, player_name}
         ]) do
      {:badrpc, _reason} -> {:error, :server_not_found}
      result -> result
    end
  end

  # Server callbacks

  @impl true
  def init(name) do
    {:ok, name}
  end

  @impl true
  def handle_call({:connect, player_name}, _from, name) do
    IO.puts("#{player_name} connected")
    {:reply, {:ok, name}, name}
  end
end
