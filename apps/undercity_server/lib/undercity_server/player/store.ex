defmodule UndercityServer.Player.Store do
  @moduledoc """
  Shared DETS-backed persistence for player state.

  A single DETS table (`data/players/players.dets`) stores all player records
  keyed by player ID. Also provides lookup operations for identity resolution
  (find by name, get display names). Used by both the Player GenServer for
  persistence and by Session/Vicinity for player lookups.
  """

  use GenServer

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec save(String.t(), map()) :: :ok
  def save(player_id, player_data) do
    GenServer.call(via(), {:save, player_id, player_data})
  end

  @spec load(String.t()) :: {:ok, map()} | :error
  def load(player_id) do
    GenServer.call(via(), {:load, player_id})
  end

  @spec get_names([String.t()]) :: %{String.t() => String.t()}
  def get_names(player_ids) do
    GenServer.call(via(), {:get_names, player_ids})
  end

  @spec find_id_by_name(String.t()) :: {:ok, String.t()} | :error
  def find_id_by_name(name) do
    GenServer.call(via(), {:find_id_by_name, name})
  end

  defp via, do: {__MODULE__, UndercityServer.server_node()}

  # Server callbacks

  @impl true
  def init(:ok) do
    path = String.to_charlist(data_path())
    File.mkdir_p!(Path.dirname(to_string(path)))
    {:ok, :player_store} = :dets.open_file(:player_store, file: path, type: :set)
    {:ok, %{table: :player_store}}
  end

  @impl true
  def handle_call({:save, player_id, player_data}, _from, state) do
    :ok = :dets.insert(state.table, {player_id, player_data})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:load, player_id}, _from, state) do
    result =
      case :dets.lookup(state.table, player_id) do
        [{^player_id, data}] -> {:ok, data}
        [] -> :error
      end

    {:reply, result, state}
  end

  @impl true
  def handle_call({:get_names, player_ids}, _from, state) do
    names =
      Enum.reduce(player_ids, %{}, fn id, acc ->
        case :dets.lookup(state.table, id) do
          [{^id, data}] -> Map.put(acc, id, data.name)
          [] -> acc
        end
      end)

    {:reply, names, state}
  end

  @impl true
  def handle_call({:find_id_by_name, name}, _from, state) do
    result =
      :dets.foldl(
        fn {id, data}, acc ->
          if acc == :error and data.name == name, do: {:ok, id}, else: acc
        end,
        :error,
        state.table
      )

    {:reply, result, state}
  end

  @impl true
  def terminate(_reason, state) do
    :dets.close(state.table)
  end

  defp data_path do
    Path.join([File.cwd!(), "data", "players", "players.dets"])
  end
end
