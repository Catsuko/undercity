defmodule UndercityServer.GameServer do
  @moduledoc false

  use GenServer

  @connect_retries 5
  @connect_timeout 2_000
  @retry_rate 50

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, name: {:global, name})
  end

  def connect(server_name, player_name) do
    server_node = UndercityServer.server_node()
    Node.connect(server_node)
    do_connect(server_name, player_name, @connect_retries)
  end

  defp do_connect(_, _, 0) do
    {:error, :server_not_found}
  end

  defp do_connect(server_name, player_name, retries) do
    try do
      GenServer.call({:global, server_name}, {:connect, player_name}, @connect_timeout)
    catch
      :exit, {:noproc, _} ->
        attempt = @connect_retries + 1 - retries
        Process.sleep((:math.pow(2, attempt) * @retry_rate) |> trunc())
        do_connect(server_name, player_name, retries - 1)

      :exit, {:nodedown, _} ->
        {:error, :server_down}
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
