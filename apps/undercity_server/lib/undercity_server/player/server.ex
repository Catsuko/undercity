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
  alias UndercityCore.Food
  alias UndercityCore.Health
  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityServer.Player.Store, as: PlayerStore

  @idle_timeout_ms Application.compile_env(:undercity_server, :player_idle_timeout_ms, 15 * 60 * 1_000)

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, {id, name}, name: process_name(id))
  end

  def process_name(player_id), do: :"player_#{player_id}"

  def via(player_id), do: {process_name(player_id), UndercityServer.server_node()}

  # Server callbacks

  @impl true
  def init({id, name}) do
    state =
      case PlayerStore.load(id) do
        {:ok, data} ->
          Map.put_new(data, :block_id, nil)

        :error ->
          %{
            id: id,
            name: name,
            inventory: Inventory.new(),
            action_points: ActionPoints.new(),
            health: Health.new(),
            block_id: nil
          }
      end

    {:ok, state, @idle_timeout_ms}
  end

  @impl true
  def handle_call({:add_item, %Item{} = item}, _from, state) do
    case Inventory.add_item(state.inventory, item) do
      {:ok, new_inventory} ->
        state = %{state | inventory: new_inventory}
        save!(state)
        {:reply, :ok, state, @idle_timeout_ms}

      {:error, :full} ->
        {:reply, {:error, :full}, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call({:drop_item, index}, _from, state) do
    items = Inventory.list_items(state.inventory)

    with {:index, true} <- {:index, index >= 0 and index < length(items)},
         {:ok, state} <- exert(state, 1) do
      item_name = Enum.at(items, index).name
      state = %{state | inventory: Inventory.remove_at(state.inventory, index)}
      save!(state)
      {:reply, {:ok, item_name, ActionPoints.current(state.action_points)}, state, @idle_timeout_ms}
    else
      {:index, false} -> {:reply, {:error, :invalid_index}, state, @idle_timeout_ms}
      {:error, _} = error -> {:reply, error, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call({:eat_item, index}, _from, state) do
    items = Inventory.list_items(state.inventory)

    with {:index, true} <- {:index, index >= 0 and index < length(items)},
         item = Enum.at(items, index),
         {:edible, effect} when effect != :not_edible <- {:edible, Food.effect(item.name)},
         {:ok, state} <- exert(state, 1) do
      health = Health.apply_effect(state.health, effect)
      inventory = Inventory.remove_at(state.inventory, index)
      state = %{state | inventory: inventory, health: health}
      save!(state)

      {:reply, {:ok, item, effect, ActionPoints.current(state.action_points), Health.current(health)}, state,
       @idle_timeout_ms}
    else
      {:index, false} -> {:reply, {:error, :invalid_index}, state, @idle_timeout_ms}
      {:edible, :not_edible} -> {:reply, {:error, :not_edible, Enum.at(items, index).name}, state, @idle_timeout_ms}
      {:error, _} = error -> {:reply, error, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call(:check_inventory, _from, state) do
    {:reply, Inventory.list_items(state.inventory), state, @idle_timeout_ms}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state, @idle_timeout_ms}
  end

  @impl true
  def handle_call({:use_item, item_name}, _from, state) do
    case consume_item(state.inventory, item_name) do
      {:ok, inventory} ->
        state = %{state | inventory: inventory}
        save!(state)
        {:reply, :ok, state, @idle_timeout_ms}

      {:error, :item_missing} ->
        {:reply, :not_found, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call({:use_item, item_name, cost}, _from, state) do
    with {:ok, inventory} <- consume_item(state.inventory, item_name),
         {:ok, state} <- exert(state, cost) do
      state = %{state | inventory: inventory}
      save!(state)
      {:reply, {:ok, ActionPoints.current(state.action_points)}, state, @idle_timeout_ms}
    else
      {:error, :item_missing} -> {:reply, {:error, :item_missing}, state, @idle_timeout_ms}
      {:error, _} = error -> {:reply, error, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call({:spend_ap, cost}, _from, state) do
    case exert(state, cost) do
      {:ok, state} ->
        save!(state)
        {:reply, {:ok, ActionPoints.current(state.action_points)}, state, @idle_timeout_ms}

      {:error, _} = error ->
        {:reply, error, state, @idle_timeout_ms}
    end
  end

  @impl true
  def handle_call(:constitution, _from, state) do
    action_points = ActionPoints.regenerate(state.action_points)
    state = %{state | action_points: action_points}
    {:reply, %{ap: ActionPoints.current(action_points), hp: Health.current(state.health)}, state, @idle_timeout_ms}
  end

  @impl true
  def handle_call(:location, _from, state) do
    {:reply, Map.get(state, :block_id), state, @idle_timeout_ms}
  end

  @impl true
  def handle_call({:move_to, block_id}, _from, state) do
    state = Map.put(state, :block_id, block_id)
    save!(state)
    {:reply, :ok, state, @idle_timeout_ms}
  end

  @impl true
  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

  defp save!(state) do
    :ok = PlayerStore.save(state.id, state)
  end

  defp exert(state, cost) do
    if Health.current(state.health) == 0 do
      {:error, :collapsed}
    else
      action_points = ActionPoints.regenerate(state.action_points)

      case ActionPoints.spend(action_points, cost) do
        {:ok, action_points} ->
          {:ok, %{state | action_points: action_points}}

        {:error, :exhausted} ->
          {:error, :exhausted}
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
end
