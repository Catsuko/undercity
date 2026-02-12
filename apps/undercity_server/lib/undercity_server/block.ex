defmodule UndercityServer.Block do
  @moduledoc """
  A GenServer that manages a Block in the undercity.
  """

  use GenServer

  alias UndercityCore.Block, as: CoreBlock
  alias UndercityCore.LootTable
  alias UndercityCore.Search
  alias UndercityServer.Store

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    type = Keyword.fetch!(opts, :type)
    exits = Keyword.get(opts, :exits, %{})

    GenServer.start_link(__MODULE__, {id, name, type, exits}, name: process_name(id))
  end

  def join(block_id, player_id) when is_binary(player_id) do
    GenServer.call(process_name(block_id), {:join, player_id})
  end

  def leave(block_id, player_id) when is_binary(player_id) do
    GenServer.call(process_name(block_id), {:leave, player_id})
  end

  def has_person?(block_id, player_id) when is_binary(player_id) do
    GenServer.call(process_name(block_id), {:has_person, player_id})
  end

  def info(block_id) do
    GenServer.call(process_name(block_id), :info)
  end

  def search(block_id) do
    GenServer.call(process_name(block_id), :search)
  end

  def process_name(id), do: :"block_#{id}"

  # Server callbacks

  @impl true
  def init({id, name, type, exits}) do
    block =
      case Store.load_block(id) do
        {:ok, persisted} -> persisted
        :error -> CoreBlock.new(id, name, type, exits)
      end

    {:ok, block}
  end

  @impl true
  def handle_call({:join, player_id}, _from, block) do
    block = CoreBlock.add_person(block, player_id)
    Store.save_block(block.id, block)
    {:reply, block_info(block), block}
  end

  @impl true
  def handle_call({:leave, player_id}, _from, block) do
    block = CoreBlock.remove_person(block, player_id)
    Store.save_block(block.id, block)
    {:reply, :ok, block}
  end

  @impl true
  def handle_call({:has_person, player_id}, _from, block) do
    {:reply, CoreBlock.has_person?(block, player_id), block}
  end

  @impl true
  def handle_call(:info, _from, block) do
    {:reply, block_info(block), block}
  end

  @impl true
  def handle_call(:search, _from, block) do
    loot_table = LootTable.for_block_type(block.type)
    {:reply, Search.search(loot_table), block}
  end

  defp block_info(block), do: {block.id, CoreBlock.list_people(block)}
end
