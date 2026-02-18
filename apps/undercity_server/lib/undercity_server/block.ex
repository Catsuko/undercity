defmodule UndercityServer.Block do
  @moduledoc """
  GenServer managing a single block's runtime state.

  Each block in the world map runs as a named process. The client API
  provides operations for joining, leaving, searching, and scribbling.
  Persistence is handled by `Block.Store`; pure domain logic lives in
  `UndercityCore.Block`.
  """

  use GenServer

  alias UndercityCore.Block, as: CoreBlock
  alias UndercityCore.Search
  alias UndercityServer.Block.Store

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    type = Keyword.fetch!(opts, :type)
    exits = Keyword.get(opts, :exits, %{})
    random = Keyword.get(opts, :random, &:rand.uniform/0)

    GenServer.start_link(__MODULE__, {id, name, type, exits, random}, name: process_name(id))
  end

  def join(block_id, player_id) when is_binary(player_id) do
    GenServer.call(via(block_id), {:join, player_id})
  end

  def leave(block_id, player_id) when is_binary(player_id) do
    GenServer.call(via(block_id), {:leave, player_id})
  end

  def has_person?(block_id, player_id) when is_binary(player_id) do
    GenServer.call(via(block_id), {:has_person, player_id})
  end

  def info(block_id) do
    GenServer.call(via(block_id), :info)
  end

  def search(block_id) do
    GenServer.call(via(block_id), :search)
  end

  def scribble(block_id, text) when is_binary(text) do
    GenServer.call(via(block_id), {:scribble, text})
  end

  def get_scribble(block_id) do
    GenServer.call(via(block_id), :get_scribble)
  end

  def process_name(id), do: :"block_#{id}"

  defp via(block_id), do: {process_name(block_id), UndercityServer.server_node()}

  # Server callbacks

  @impl true
  def init({id, name, type, exits, random}) do
    block =
      case Store.load_block(id) do
        {:ok, persisted} -> persisted
        :error -> CoreBlock.new(id, name, type, exits)
      end

    {:ok, {block, random}}
  end

  @impl true
  def handle_call({:join, player_id}, _from, {block, random}) do
    block = CoreBlock.add_person(block, player_id)
    Store.save_block(block.id, block)
    {:reply, block_info(block), {block, random}}
  end

  @impl true
  def handle_call({:leave, player_id}, _from, {block, random}) do
    block = CoreBlock.remove_person(block, player_id)
    Store.save_block(block.id, block)
    {:reply, :ok, {block, random}}
  end

  @impl true
  def handle_call({:has_person, player_id}, _from, {block, random}) do
    {:reply, CoreBlock.has_person?(block, player_id), {block, random}}
  end

  @impl true
  def handle_call(:info, _from, {block, random}) do
    {:reply, block_info(block), {block, random}}
  end

  @impl true
  def handle_call(:search, _from, {block, random}) do
    {:reply, Search.search(block.type, random.()), {block, random}}
  end

  @impl true
  def handle_call({:scribble, text}, _from, {block, random}) do
    block = CoreBlock.scribble(block, text)
    Store.save_block(block.id, block)
    {:reply, :ok, {block, random}}
  end

  @impl true
  def handle_call(:get_scribble, _from, {block, random}) do
    {:reply, block.scribble, {block, random}}
  end

  defp block_info(block), do: {block.id, CoreBlock.list_people(block)}
end
