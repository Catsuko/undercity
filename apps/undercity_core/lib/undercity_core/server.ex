defmodule UndercityCore.Server do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: via(name))
  end

  def connect(server_name) do
    GenServer.call(via(server_name), :connect)
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
  def handle_call(:connect, _from, name) do
    {:reply, {:ok, name}, name}
  end
end
