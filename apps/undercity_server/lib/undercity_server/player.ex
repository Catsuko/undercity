defmodule UndercityServer.Player do
  @moduledoc """
  Facade over `Player.Server` providing the public API for all player state operations.

  - Holds no state; every call delegates to the per-player `Player.Server` GenServer via `Player.Server.call/3`
  - Starts the player process on demand if it has stopped due to idle timeout (lazy-start)
  - All mutations are persisted to DETS through `Player.Store` before the GenServer replies
  - Callers never need to manage process lifecycle — `Player.Server.call/3` handles start-on-demand automatically
  """

  alias UndercityCore.Item
  alias UndercityServer.Player.Server, as: PlayerServer
  alias UndercityServer.Player.Supervisor, as: PlayerSupervisor

  # Client API

  @doc """
  Adds `item` to the player's inventory and persists the change.

  - Returns `:ok` on success.
  - Returns `{:error, :full}` if the inventory has no remaining capacity.
  """
  @spec add_item(String.t(), Item.t()) :: :ok | {:error, :full}
  def add_item(player_id, %Item{} = item) do
    PlayerServer.call(player_id, PlayerSupervisor, {:add_item, item})
  end

  @doc """
  Drops the item at `index` from the player's inventory, spending 1 AP.

  - Returns `{:ok, ap}` on success.
  - Returns `{:error, :invalid_index}` if the index is out of range.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  @spec drop_item(String.t(), non_neg_integer()) ::
          {:ok, non_neg_integer()}
          | {:error, :invalid_index}
          | {:error, :exhausted}
          | {:error, :collapsed}
  def drop_item(player_id, index) do
    PlayerServer.call(player_id, PlayerSupervisor, {:drop_item, index})
  end

  @doc """
  Eats the item at `index` in the player's inventory, spending 1 AP and applying the food effect.

  - Returns `{:ok, ap, hp}` on success.
  - Returns `{:error, :invalid_index}` if no item exists at that position.
  - Returns `{:error, :not_edible, item_name}` if the item cannot be eaten.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  @spec eat_item(String.t(), non_neg_integer()) ::
          {:ok, non_neg_integer(), non_neg_integer()}
          | {:error, :invalid_index}
          | {:error, :not_edible, String.t()}
          | {:error, :exhausted}
          | {:error, :collapsed}
  def eat_item(player_id, index) do
    PlayerServer.call(player_id, PlayerSupervisor, {:eat_item, index})
  end

  @doc """
  Returns the list of items currently in the player's inventory.
  """
  @spec check_inventory(String.t()) :: [Item.t()]
  def check_inventory(player_id) do
    PlayerServer.call(player_id, PlayerSupervisor, :check_inventory)
  end

  @doc """
  Consumes one use of `item_name` from the player's inventory without spending AP.

  - Returns `:ok` on success.
  - Returns `:not_found` if no matching item exists in the inventory.
  """
  @spec use_item(String.t(), String.t()) :: :ok | :not_found
  def use_item(player_id, item_name) do
    PlayerServer.call(player_id, PlayerSupervisor, {:use_item, item_name})
  end

  @doc """
  Consumes one use of an item and spends `cost` AP atomically.

  - `item` may be an item name (string) or an inventory index (integer).
  - Returns `{:ok, ap}` on success, where `ap` is the remaining action points.
  - Returns `{:error, :item_missing}` if the item is not found.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  @spec use_item(String.t(), String.t(), pos_integer()) ::
          {:ok, non_neg_integer()} | {:error, :exhausted} | {:error, :collapsed} | {:error, :item_missing}
  @spec use_item(String.t(), non_neg_integer(), pos_integer()) ::
          {:ok, non_neg_integer()} | {:error, :exhausted} | {:error, :collapsed} | {:error, :item_missing}
  def use_item(player_id, item, cost) do
    PlayerServer.call(player_id, PlayerSupervisor, {:use_item, item, cost})
  end

  @doc """
  Spends `cost` AP and executes `action_fn` if the player is able.

  - Returns `{:ok, result, ap}` where `result` is the return value of `action_fn`.
  - Returns `{:error, :exhausted}` if the player has insufficient AP.
  - Returns `{:error, :collapsed}` if the player's HP is zero.
  - `cost` defaults to 1.
  """
  @spec perform(String.t(), pos_integer(), (-> any())) ::
          {:ok, any(), non_neg_integer()} | {:error, :exhausted} | {:error, :collapsed}
  def perform(player_id, cost \\ 1, action_fn) do
    case PlayerServer.call(player_id, PlayerSupervisor, {:spend_ap, cost}) do
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
    PlayerServer.call(player_id, PlayerSupervisor, :constitution)
  end

  @doc """
  Applies `damage` to the player's health and sends inbox notifications to both the target and attacker.

  - Fire-and-forget: returns `:ok` immediately without waiting for the result.
  - Silently drops if the target is already at zero HP.
  - Side effect: delivers a warning inbox message to the target and a success inbox message to the attacker.
  """
  @spec take_damage(String.t(), {String.t(), String.t(), pos_integer()}) :: :ok
  def take_damage(player_id, {attacker_id, attacker_name, damage}) do
    PlayerServer.cast(player_id, PlayerSupervisor, {:take_damage, {attacker_id, attacker_name, damage}})
  end

  @doc """
  Applies up to `amount` HP healing to the player, capped at their maximum HP.

  - Returns `{:ok, healed}` where `healed` is the actual HP restored (may be 0 if at max).
  - Returns `{:error, :invalid_target}` if the player is collapsed (HP is zero).
  - Side effect: delivers an inbox notification if `healer_id` differs from `player_id` and healing occurred.
  """
  @spec heal(String.t(), pos_integer(), String.t(), String.t()) :: {:ok, non_neg_integer()} | {:error, :invalid_target}
  def heal(player_id, amount, healer_id, healer_name) do
    PlayerServer.call(player_id, PlayerSupervisor, {:heal, amount, healer_id, healer_name})
  end

  @doc """
  Atomically fetches and clears up to 50 pending inbox messages for the player.

  Returns a list of `{text}` tuples in newest-first order, or `[]` if there are no messages.
  """
  @spec fetch_inbox(String.t()) :: [{String.t()}]
  def fetch_inbox(player_id) do
    PlayerServer.call(player_id, PlayerSupervisor, :fetch_inbox)
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
    PlayerServer.call(player_id, PlayerSupervisor, :location)
  end

  @doc """
  Records `block_id` as the player's current location and persists the change.

  Returns `:ok`. Always call this alongside `Block.join/2` to keep the two sources of truth consistent.
  """
  @spec move_to(String.t(), String.t()) :: :ok
  def move_to(player_id, block_id) do
    PlayerServer.call(player_id, PlayerSupervisor, {:move_to, block_id})
  end
end
