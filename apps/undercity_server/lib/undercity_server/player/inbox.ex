defmodule UndercityServer.Player.Inbox do
  @moduledoc """
  ETS-backed inbox for delivering server-to-player notifications.

  - Owns a named ETS table and serialises all writes through a single GenServer to prevent concurrent prepend races
  - Reads bypass the GenServer — `fetch/2` calls `:ets.take/2` directly for an atomic fetch-and-clear
  - Messages are stored newest-first as `{text}` tuples keyed by `player_id`
  - No persistence: the table is in-memory only and cleared when the GenServer stops
  """

  use GenServer

  @table __MODULE__

  # Client API

  @doc """
  Starts the Inbox GenServer and creates the shared ETS table.

  Registers the process globally as `UndercityServer.Player.Inbox`.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc """
  Enqueues `text` as a new message for `player_id`.

  Serialised through the GenServer to avoid concurrent prepend races.
  Returns immediately (cast).
  """
  @spec send_message(String.t(), String.t()) :: :ok
  def send_message(player_id, text) do
    GenServer.cast(__MODULE__, {:send_message, player_id, text})
  end

  @doc """
  Atomically fetches and clears up to `n` messages for `player_id`.

  Reads ETS directly — no GenServer hop. Returns messages in newest-first
  order. Returns `[]` if no messages exist for `player_id`.
  """
  @spec fetch(String.t(), pos_integer()) :: [{String.t()}]
  def fetch(player_id, n \\ 50) do
    case :ets.take(@table, player_id) do
      [{^player_id, messages}] -> messages |> Enum.take(n) |> Enum.reverse()
      [] -> []
    end
  end

  # Server callbacks

  @doc false
  @impl true
  def init(:ok) do
    table = :ets.new(@table, [:named_table, :set, :public])
    {:ok, %{table: table}}
  end

  @doc false
  @impl true
  def handle_cast({:send_message, player_id, text}, state) do
    messages =
      case :ets.lookup(@table, player_id) do
        [{^player_id, existing}] -> existing
        [] -> []
      end

    :ets.insert(@table, {player_id, [{text} | messages]})
    {:noreply, state}
  end
end
