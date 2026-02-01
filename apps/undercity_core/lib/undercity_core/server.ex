defmodule UndercityCore.Server do
  @moduledoc false

  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: {:global, {__MODULE__, name}})
  end

  def connect(server_name, player_name) do
    Node.connect(UndercityCore.server_node())
    :global.sync()
    GenServer.call({:global, {__MODULE__, server_name}}, {:connect, player_name})
  catch
    :exit, _ -> {:error, :server_not_found}
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
