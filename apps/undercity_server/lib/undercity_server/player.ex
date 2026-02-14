defmodule UndercityServer.Player do
  @moduledoc """
  GenServer managing a single player's runtime state.

  Each connected player runs as a dynamically supervised process. Manages
  inventory (add, use, list items) and action points (AP). Player processes
  are started on demand by `Player.Supervisor` and persist state through
  `Player.Store`.

  Owns its own process naming — player IDs are mapped to registered atom
  names internally. ID generation lives in `Session` where new players are
  created.
  """

  use GenServer

  alias UndercityCore.ActionPoints
  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityServer.Player.Store, as: PlayerStore

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, {id, name}, name: process_name(id))
  end

  @spec add_item(String.t(), Item.t()) :: :ok
  def add_item(player_id, %Item{} = item) do
    GenServer.cast(via(player_id), {:add_item, item})
  end

  @spec get_inventory(String.t()) :: [Item.t()]
  def get_inventory(player_id) do
    GenServer.call(via(player_id), :get_inventory)
  end

  @spec get_name(String.t()) :: String.t()
  def get_name(player_id) do
    GenServer.call(via(player_id), :get_name)
  end

  @spec use_item(String.t(), String.t()) :: {:ok, Item.t()} | :not_found
  def use_item(player_id, item_name) do
    GenServer.call(via(player_id), {:use_item, item_name})
  end

  @spec use_item(String.t(), String.t(), pos_integer()) ::
          {:ok, Item.t(), non_neg_integer()} | {:error, :exhausted} | {:error, :not_found}
  def use_item(player_id, item_name, cost) do
    GenServer.call(via(player_id), {:use_item, item_name, cost})
  end

  @spec perform(String.t(), pos_integer(), (-> any())) :: {:ok, any(), non_neg_integer()} | {:error, :exhausted}
  def perform(player_id, cost \\ 1, action_fn) do
    case GenServer.call(via(player_id), {:spend_ap, cost}) do
      {:ok, ap} -> {:ok, action_fn.(), ap}
      {:error, :exhausted} -> {:error, :exhausted}
    end
  end

  @spec get_ap(String.t()) :: non_neg_integer()
  def get_ap(player_id) do
    GenServer.call(via(player_id), :get_ap)
  end

  defp process_name(player_id), do: :"player_#{player_id}"

  defp via(player_id), do: {process_name(player_id), UndercityServer.server_node()}

  # Server callbacks

  @impl true
  def init({id, name}) do
    state =
      case PlayerStore.load(id) do
        {:ok, data} ->
          data

        :error ->
          %{id: id, name: name, inventory: Inventory.new(), action_points: ActionPoints.new()}
      end

    {:ok, state}
  end

  @impl true
  def handle_cast({:add_item, %Item{} = item}, state) do
    new_inventory = Inventory.add_item(state.inventory, item)
    state = %{state | inventory: new_inventory}
    PlayerStore.save(state.id, state)
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_inventory, _from, state) do
    {:reply, Inventory.list_items(state.inventory), state}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state}
  end

  @impl true
  def handle_call({:use_item, item_name}, _from, state) do
    case consume_item(state.inventory, item_name) do
      {:ok, inventory, item} ->
        state = %{state | inventory: inventory}
        PlayerStore.save(state.id, state)
        {:reply, {:ok, item}, state}

      {:error, :not_found} ->
        {:reply, :not_found, state}
    end
  end

  @impl true
  def handle_call({:use_item, item_name, cost}, _from, state) do
    action_points = ActionPoints.regenerate(state.action_points)

    with {:ok, action_points} <- ActionPoints.spend(action_points, cost),
         {:ok, inventory, item} <- consume_item(state.inventory, item_name) do
      state = %{state | action_points: action_points, inventory: inventory}
      PlayerStore.save(state.id, state)
      {:reply, {:ok, item, ActionPoints.current(action_points)}, state}
    else
      {:error, :exhausted} -> {:reply, {:error, :exhausted}, state}
      {:error, :not_found} -> {:reply, {:error, :not_found}, state}
    end
  end

  @impl true
  def handle_call({:spend_ap, cost}, _from, state) do
    action_points = ActionPoints.regenerate(state.action_points)

    case ActionPoints.spend(action_points, cost) do
      {:ok, action_points} ->
        state = %{state | action_points: action_points}
        PlayerStore.save(state.id, state)
        {:reply, {:ok, ActionPoints.current(action_points)}, state}

      {:error, :exhausted} ->
        {:reply, {:error, :exhausted}, state}
    end
  end

  @impl true
  def handle_call(:get_ap, _from, state) do
    action_points = ActionPoints.regenerate(state.action_points)
    state = %{state | action_points: action_points}
    {:reply, ActionPoints.current(action_points), state}
  end

  defp consume_item(inventory, item_name) do
    case Inventory.find_item(inventory, item_name) do
      {:ok, item, index} ->
        case Item.use(item) do
          {:ok, updated} -> {:ok, Inventory.replace_at(inventory, index, updated), updated}
          :spent -> {:ok, Inventory.remove_at(inventory, index), item}
        end

      :not_found ->
        {:error, :not_found}
    end
  end
end
