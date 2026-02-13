defmodule UndercityServer.Player do
  @moduledoc """
  GenServer managing a single player's mutable state (inventory, etc.).
  """

  use GenServer

  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityServer.Player.Identity
  alias UndercityServer.Player.Store, as: PlayerStore

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, {id, name}, name: Identity.via(id))
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

  defp via(player_id), do: {Identity.via(player_id), UndercityServer.server_node()}

  # Server callbacks

  @impl true
  def init({id, name}) do
    state =
      case PlayerStore.load(id) do
        {:ok, data} ->
          data

        :error ->
          %{id: id, name: name, inventory: Inventory.new()}
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
    case Inventory.find_item(state.inventory, item_name) do
      {:ok, item, index} ->
        case Item.use(item) do
          {:ok, updated_item} ->
            inventory = Inventory.replace_at(state.inventory, index, updated_item)
            state = %{state | inventory: inventory}
            PlayerStore.save(state.id, state)
            {:reply, {:ok, updated_item}, state}

          :spent ->
            inventory = Inventory.remove_at(state.inventory, index)
            state = %{state | inventory: inventory}
            PlayerStore.save(state.id, state)
            {:reply, {:ok, item}, state}
        end

      :not_found ->
        {:reply, :not_found, state}
    end
  end
end
