defmodule UndercityServer.Player do
  @moduledoc """
  Public API for player state.

  ## Architecture

  Player state is managed by `Player.Server`, a GenServer that runs one
  process per active player. This module is a pure facade: it holds no
  state of its own and every function delegates to the underlying
  GenServer via `GenServer.call/2`.

  ### Lazy loading

  Player processes are not kept alive indefinitely. After
  `player_idle_timeout_ms` of inactivity (configurable, default 15 minutes)
  the GenServer stops itself with a normal exit. Before each call this
  module calls `start_if_inactive/1`, which starts the process from
  `Player.Store` if it is not already running, so callers never need
  to manage process lifecycle themselves.

  ### Persistence

  All mutations are written to DETS through `Player.Store` before the
  GenServer replies. The store is the source of truth; the GenServer is
  an in-memory cache of a player's current session state.

  ### Process naming

  Processes are registered under `:"player_<id>"` on the server node.
  Naming is owned by `Player.Server`; everything else goes through
  `Player.Server.via/1`.
  """

  alias UndercityCore.Item
  alias UndercityServer.Player.Server, as: PlayerServer
  alias UndercityServer.Player.Store, as: PlayerStore
  alias UndercityServer.Player.Supervisor, as: PlayerSupervisor

  # Client API

  @spec add_item(String.t(), Item.t()) :: :ok | {:error, :full}
  def add_item(player_id, %Item{} = item) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), {:add_item, item})
  end

  @spec drop_item(String.t(), non_neg_integer()) ::
          {:ok, String.t(), non_neg_integer()}
          | {:error, :invalid_index}
          | {:error, :exhausted}
          | {:error, :collapsed}
  def drop_item(player_id, index) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), {:drop_item, index})
  end

  @spec eat_item(String.t(), non_neg_integer()) ::
          {:ok, Item.t(), {:heal, pos_integer()} | {:damage, pos_integer()}, non_neg_integer(), non_neg_integer()}
          | {:error, :invalid_index}
          | {:error, :not_edible, String.t()}
          | {:error, :exhausted}
          | {:error, :collapsed}
  def eat_item(player_id, index) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), {:eat_item, index})
  end

  @spec check_inventory(String.t()) :: [Item.t()]
  def check_inventory(player_id) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), :check_inventory)
  end

  @spec get_name(String.t()) :: String.t()
  def get_name(player_id) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), :get_name)
  end

  @spec use_item(String.t(), String.t()) :: :ok | :not_found
  def use_item(player_id, item_name) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), {:use_item, item_name})
  end

  @spec use_item(String.t(), String.t(), pos_integer()) ::
          {:ok, non_neg_integer()} | {:error, :exhausted} | {:error, :collapsed} | {:error, :item_missing}
  def use_item(player_id, item_name, cost) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), {:use_item, item_name, cost})
  end

  @spec perform(String.t(), pos_integer(), (-> any())) ::
          {:ok, any(), non_neg_integer()} | {:error, :exhausted} | {:error, :collapsed}
  def perform(player_id, cost \\ 1, action_fn) do
    start_if_inactive(player_id)

    case GenServer.call(PlayerServer.via(player_id), {:spend_ap, cost}) do
      {:ok, ap} -> {:ok, action_fn.(), ap}
      {:error, _} = error -> error
    end
  end

  @doc """
  Returns the player's physical state — attributes that reflect their
  current condition in the world (e.g. action points, health, and
  eventually stamina or status effects).
  """
  @spec constitution(String.t()) :: %{ap: non_neg_integer(), hp: non_neg_integer()}
  def constitution(player_id) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), :constitution)
  end

  @doc """
  Returns the block ID the player is currently located in, or `nil` if no
  location has been recorded yet.

  This is the player's authoritative position, persisted to DETS on every
  move. It is used as a fast lookup on reconnect to avoid scanning all blocks,
  and is always kept consistent with the block's own player list: `move_to/2`
  is called before `Block.join/2`, so the player can never appear in a block
  without a matching location record.
  """
  @spec location(String.t()) :: String.t() | nil
  def location(player_id) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), :location)
  end

  @spec move_to(String.t(), String.t()) :: :ok
  def move_to(player_id, block_id) do
    start_if_inactive(player_id)
    GenServer.call(PlayerServer.via(player_id), {:move_to, block_id})
  end

  defp start_if_inactive(player_id) do
    case GenServer.whereis(PlayerServer.process_name(player_id)) do
      nil ->
        {:ok, %{name: name}} = PlayerStore.load(player_id)

        case PlayerSupervisor.start_player(player_id, name) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

      _pid ->
        :ok
    end
  end
end
