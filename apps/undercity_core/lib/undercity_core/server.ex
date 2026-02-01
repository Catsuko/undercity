defmodule UndercityCore.Server do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: via(name))
  end

  def connect(server_name, player_name) do
    GenServer.call(via(server_name), {:connect, player_name})
  end

  defp via(name) do
    {:via, Registry, {UndercityCore.ServerRegistry, name}}
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
