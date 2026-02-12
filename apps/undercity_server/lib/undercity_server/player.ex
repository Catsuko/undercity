defmodule UndercityServer.Player do
  @moduledoc """
  GenServer managing a single player's mutable state (inventory, etc.).
  """

  use GenServer

  alias UndercityCore.Inventory
  alias UndercityCore.Search
  alias UndercityServer.PlayerIdentity
  alias UndercityServer.PlayerStore

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, {id, name}, name: PlayerIdentity.via(id))
  end

  @spec search(String.t()) :: {:found, UndercityCore.Item.t()} | :nothing | :inventory_full
  def search(player_id) do
    GenServer.call(PlayerIdentity.via(player_id), :search)
  end

  @spec get_inventory(String.t()) :: [UndercityCore.Item.t()]
  def get_inventory(player_id) do
    GenServer.call(PlayerIdentity.via(player_id), :get_inventory)
  end

  @spec get_name(String.t()) :: String.t()
  def get_name(player_id) do
    GenServer.call(PlayerIdentity.via(player_id), :get_name)
  end

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
  def handle_call(:search, _from, state) do
    case Search.search(state.inventory) do
      {:found, item, new_inventory} ->
        state = %{state | inventory: new_inventory}
        PlayerStore.save(state.id, state)
        {:reply, {:found, item}, state}

      :nothing ->
        {:reply, :nothing, state}
    end
  end

  @impl true
  def handle_call(:get_inventory, _from, state) do
    {:reply, Inventory.list_items(state.inventory), state}
  end

  @impl true
  def handle_call(:get_name, _from, state) do
    {:reply, state.name, state}
  end
end
