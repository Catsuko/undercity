defmodule UndercityServer.Player.Inbox do
  @moduledoc """
  ETS-backed inbox for per-player server-to-player notifications.

  A single GenServer owns the ETS table and serialises all writes through
  itself to avoid concurrent append races. Reads bypass the GenServer
  entirely — `fetch/2` calls `:ets.take/2` directly for an atomic
  fetch-and-clear with no extra message hop.

  Messages are stored newest-first (prepended on insert) as `{text}` tuples
  under the key `player_id`. There is no persistence: the table lives only
  in memory and is cleared automatically when the GenServer stops.
  """

  use GenServer

  @table __MODULE__

  # Client API

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

  @impl true
  def init(:ok) do
    table = :ets.new(@table, [:named_table, :set, :public])
    {:ok, %{table: table}}
  end

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
