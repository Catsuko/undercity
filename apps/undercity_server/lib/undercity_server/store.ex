defmodule UndercityServer.Store do
  @moduledoc """
  Per-block disk-backed persistence using DETS.
  Each block gets its own DETS file under data/blocks/.
  """

  use GenServer

  # Client API

  def start_link(block_id) do
    GenServer.start_link(__MODULE__, block_id, name: process_name(block_id))
  end

  def save_block(block_id, block) do
    GenServer.call(process_name(block_id), {:save, block})
  end

  def load_block(block_id) do
    GenServer.call(process_name(block_id), :load)
  end

  defp process_name(block_id), do: :"store_#{block_id}"

  # Server callbacks

  @impl true
  def init(block_id) do
    path = block_id |> data_path() |> String.to_charlist()
    File.mkdir_p!(Path.dirname(to_string(path)))
    table = String.to_atom("store_#{block_id}")
    {:ok, ^table} = :dets.open_file(table, file: path, type: :set)
    {:ok, %{table: table, block_id: block_id}}
  end

  @impl true
  def handle_call({:save, block}, _from, state) do
    :ok = :dets.insert(state.table, {:block, block})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:load, _from, state) do
    result =
      case :dets.lookup(state.table, :block) do
        [{:block, block}] -> {:ok, block}
        [] -> :error
      end

    {:reply, result, state}
  end

  @impl true
  def terminate(_reason, state) do
    :dets.close(state.table)
  end

  defp data_path(block_id) do
    Path.join([File.cwd!(), "data", "blocks", "#{block_id}.dets"])
  end
end
