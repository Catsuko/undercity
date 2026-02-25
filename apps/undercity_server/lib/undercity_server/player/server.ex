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
  alias UndercityServer.Player.Store, as: PlayerStore

  @idle_timeout_ms Application.compile_env(:undercity_server, :player_idle_timeout_ms, 15 * 60 * 1_000)

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, {id, name}, name: process_name(id))
  end

  def call(player_id, supervisor, message) do
    ensure_started(player_id, supervisor)
    GenServer.call(via(player_id), message)
  end

  defp process_name(player_id), do: :"player_#{player_id}"

  defp via(player_id), do: {process_name(player_id), UndercityServer.server_node()}

  # Server callbacks

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

  @impl true
  def handle_call(:check_inventory, _from, state) do
    {:reply, Inventory.list_items(state.player.inventory), state, @idle_timeout_ms}
  end

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

  @impl true
  def handle_call({:use_item, item_name, cost}, _from, state) do
    with {:ok, inventory} <- consume_item(state.player.inventory, item_name),
         {:ok, player} <- Player.exert(state.player, cost, now()) do
      state = %{state | player: %{player | inventory: inventory}}
      save!(state)
      {:reply, {:ok, ActionPoints.current(state.player.action_points)}, state, @idle_timeout_ms}
    else
      {:error, _} = error -> {:reply, error, state, @idle_timeout_ms}
    end
  end

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

  @impl true
  def handle_call({:take_damage, amount}, _from, state) do
    if Health.current(state.player.health) == 0 do
      {:reply, {:error, :collapsed}, state, @idle_timeout_ms}
    else
      health = Health.apply_effect(state.player.health, {:damage, amount})
      player = %{state.player | health: health}
      state = %{state | player: player}
      save!(state)
      {:reply, {:ok, Health.current(health)}, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call(:constitution, _from, state) do
    action_points = ActionPoints.regenerate(state.player.action_points)
    player = %{state.player | action_points: action_points}
    state = %{state | player: player}
    {:reply, %{ap: ActionPoints.current(action_points), hp: Health.current(player.health)}, state, @idle_timeout_ms}
  end

  @impl true
  def handle_call(:location, _from, state) do
    {:reply, state.block_id, state, @idle_timeout_ms}
  end

  @impl true
  def handle_call({:move_to, block_id}, _from, state) do
    state = %{state | block_id: block_id}
    save!(state)
    {:reply, :ok, state, @idle_timeout_ms}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp save!(state) do
    data = state.player |> Map.from_struct() |> Map.put(:block_id, state.block_id)
    :ok = PlayerStore.save(state.player.id, data)
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
