defmodule UndercityServer.Player.Server do
  @moduledoc """
  GenServer managing a single player's runtime state.

  Handles inventory, action points, health, and block location. State is
  persisted to `Player.Store` on every mutation. Processes stop after
  `@idle_timeout_ms` of inactivity and are restarted on demand by
  `Player` when a new request arrives.
  """

  use GenServer, restart: :transient

  alias UndercityCore.ActionPoints
  alias UndercityCore.Health
  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityCore.Player
  alias UndercityServer.Player.Inbox, as: PlayerInbox
  alias UndercityServer.Player.Store, as: PlayerStore

  @idle_timeout_ms Application.compile_env(:undercity_server, :player_idle_timeout_ms, 15 * 60 * 1_000)

  @doc """
  Starts the Player GenServer for the player identified by `opts[:id]`.

  - Required keys: `:id` (player ID string), `:name` (display name string).
  - Loads persisted state from `Player.Store` on startup, or initialises a fresh player if none exists.
  - Registers the process as `:"player_{id}"`.
  """
  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, {id, name}, name: process_name(id))
  end

  @doc """
  Ensures the Player GenServer for `player_id` is running, then sends `message` via `GenServer.call/2`.

  - Starts the process under `supervisor` if it has stopped due to idle timeout.
  - All `Player` facade calls route through here.
  """
  def call(player_id, supervisor, message) do
    ensure_started(player_id, supervisor)
    GenServer.call(via(player_id), message)
  end

  defp process_name(player_id), do: :"player_#{player_id}"

  defp via(player_id), do: {process_name(player_id), UndercityServer.server_node()}

  # Server callbacks

  @doc false
  @impl true
  def init({id, name}) do
    state =
      case PlayerStore.load(id) do
        {:ok, data} ->
          player = struct(Player, Map.take(data, [:id, :name, :inventory, :action_points, :health]))
          %{player: player, block_id: Map.get(data, :block_id)}

        :error ->
          %{player: Player.new(id, name), block_id: nil}
      end

    {:ok, state, @idle_timeout_ms}
  end

  @doc false
  @impl true
  def handle_call({:add_item, %Item{} = item}, _from, state) do
    case Inventory.add_item(state.player.inventory, item) do
      {:ok, inventory} ->
        state = %{state | player: %{state.player | inventory: inventory}}
        save!(state)
        {:reply, :ok, state, @idle_timeout_ms}

      {:error, :full} ->
        {:reply, {:error, :full}, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:drop_item, index}, _from, state) do
    case Player.drop(state.player, index, now()) do
      {:ok, player, item_name} ->
        state = %{state | player: player}
        save!(state)
        {:reply, {:ok, item_name, ActionPoints.current(player.action_points)}, state, @idle_timeout_ms}

      {:error, _} = error ->
        {:reply, error, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:eat_item, index}, _from, state) do
    case Player.eat(state.player, index, now()) do
      {:ok, player, item, effect} ->
        state = %{state | player: player}
        save!(state)

        {:reply, {:ok, item, effect, ActionPoints.current(player.action_points), Health.current(player.health)}, state,
         @idle_timeout_ms}

      error ->
        {:reply, error, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call(:check_inventory, _from, state) do
    {:reply, Inventory.list_items(state.player.inventory), state, @idle_timeout_ms}
  end

  @doc false
  @impl true
  def handle_call({:use_item, item_name}, _from, state) do
    case consume_item(state.player.inventory, item_name) do
      {:ok, inventory} ->
        state = %{state | player: %{state.player | inventory: inventory}}
        save!(state)
        {:reply, :ok, state, @idle_timeout_ms}

      {:error, :item_missing} ->
        {:reply, :not_found, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:use_item, item_name, cost}, _from, state) when is_binary(item_name) do
    with {:ok, inventory} <- consume_item(state.player.inventory, item_name),
         {:ok, player} <- Player.exert(state.player, cost, now()) do
      state = %{state | player: %{player | inventory: inventory}}
      save!(state)
      {:reply, {:ok, ActionPoints.current(state.player.action_points)}, state, @idle_timeout_ms}
    else
      {:error, _} = error -> {:reply, error, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:use_item, item_idx, cost}, _from, state) when is_integer(item_idx) do
    with {:ok, inventory} <- consume_at(state.player.inventory, item_idx),
         {:ok, player} <- Player.exert(state.player, cost, now()) do
      state = %{state | player: %{player | inventory: inventory}}
      save!(state)
      {:reply, {:ok, ActionPoints.current(state.player.action_points)}, state, @idle_timeout_ms}
    else
      {:error, _} = error -> {:reply, error, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:spend_ap, cost}, _from, state) do
    case Player.exert(state.player, cost, now()) do
      {:ok, player} ->
        state = %{state | player: player}
        save!(state)
        {:reply, {:ok, ActionPoints.current(player.action_points)}, state, @idle_timeout_ms}

      {:error, _} = error ->
        {:reply, error, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:heal, amount, healer_id, healer_name}, _from, state) do
    case Health.heal(state.player.health, amount) do
      {:ok, healed, health} ->
        state = %{state | player: %{state.player | health: health}}
        save!(state)

        if healer_id != state.player.id and healed > 0 do
          PlayerInbox.send_message(state.player.id, "#{healer_name} healed you for #{healed}.")
        end

        {:reply, {:ok, healed}, state, @idle_timeout_ms}

      {:error, :collapsed} ->
        {:reply, {:error, :invalid_target}, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call({:take_damage, {attacker_name, weapon_name, damage}}, _from, state) do
    if Health.current(state.player.health) == 0 do
      {:reply, {:error, :collapsed}, state, @idle_timeout_ms}
    else
      health = Health.apply_effect(state.player.health, {:damage, damage})
      player = %{state.player | health: health}
      state = %{state | player: player}
      save!(state)

      PlayerInbox.send_message(player.id, "#{attacker_name} attacks you with #{weapon_name} and does #{damage} damage.")
      {:reply, {:ok, Health.current(health)}, state, @idle_timeout_ms}
    end
  end

  @doc false
  @impl true
  def handle_call(:fetch_inbox, _from, state) do
    {:reply, PlayerInbox.fetch(state.player.id), state, @idle_timeout_ms}
  end

  @doc false
  @impl true
  def handle_call(:constitution, _from, state) do
    action_points = ActionPoints.regenerate(state.player.action_points)
    player = %{state.player | action_points: action_points}
    state = %{state | player: player}
    {:reply, %{ap: ActionPoints.current(action_points), hp: Health.current(player.health)}, state, @idle_timeout_ms}
  end

  @doc false
  @impl true
  def handle_call(:location, _from, state) do
    {:reply, state.block_id, state, @idle_timeout_ms}
  end

  @doc false
  @impl true
  def handle_call({:move_to, block_id}, _from, state) do
    state = %{state | block_id: block_id}
    save!(state)
    {:reply, :ok, state, @idle_timeout_ms}
  end

  @doc false
  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp save!(state) do
    data = state.player |> Map.from_struct() |> Map.put(:block_id, state.block_id)
    :ok = PlayerStore.save(state.player.id, data)
  end

  defp consume_at(inventory, index) do
    case Enum.at(Inventory.list_items(inventory), index) do
      nil ->
        {:error, :item_missing}

      item ->
        case Item.use(item) do
          {:ok, updated} -> {:ok, Inventory.replace_at(inventory, index, updated)}
          :spent -> {:ok, Inventory.remove_at(inventory, index)}
        end
    end
  end

  defp consume_item(inventory, item_name) do
    case Inventory.find_item(inventory, item_name) do
      {:ok, item, index} ->
        case Item.use(item) do
          {:ok, updated} -> {:ok, Inventory.replace_at(inventory, index, updated)}
          :spent -> {:ok, Inventory.remove_at(inventory, index)}
        end

      :not_found ->
        {:error, :item_missing}
    end
  end

  defp ensure_started(player_id, supervisor) do
    case GenServer.whereis(process_name(player_id)) do
      nil ->
        {:ok, %{name: name}} = PlayerStore.load(player_id)

        case supervisor.start_player(player_id, name) do
          {:ok, _} -> :ok
          {:error, {:already_started, _}} -> :ok
        end

      _pid ->
        :ok
    end
  end

  defp now, do: System.os_time(:second)
end
