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
  alias UndercityServer.Player.Inbox, as: PlayerInbox

  # Client API

  @doc """
  Starts the Block GenServer for the block described by `opts`.

  - Required keys: `:id`, `:name`, `:type`.
  - Optional keys: `:exits` (map of direction to block ID, default `%{}`), `:random` (0-arity fun, default `:rand.uniform/0`).
  - Registers the process under the atom `:"block_{id}"`.
  """
  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    type = Keyword.fetch!(opts, :type)
    exits = Keyword.get(opts, :exits, %{})
    random = Keyword.get(opts, :random, &:rand.uniform/0)

    GenServer.start_link(__MODULE__, {id, name, type, exits, random}, name: process_name(id))
  end

  @doc """
  Adds `player_id` to the block's present-player list and persists the change.

  Returns `{block_id, [player_id]}` — the block ID and the updated list of present players.
  """
  def join(block_id, player_id) when is_binary(player_id) do
    GenServer.call(via(block_id), {:join, player_id})
  end

  @doc """
  Removes `player_id` from the block's present-player list and persists the change.

  Returns `:ok`.
  """
  def leave(block_id, player_id) when is_binary(player_id) do
    GenServer.call(via(block_id), {:leave, player_id})
  end

  @doc """
  Returns `true` if `player_id` is currently present in the block, `false` otherwise.
  """
  def has_person?(block_id, player_id) when is_binary(player_id) do
    GenServer.call(via(block_id), {:has_person, player_id})
  end

  @doc """
  Returns `{block_id, player_ids, scribble}` — the block ID, the list of currently present player IDs,
  and the current scribble text (or `nil` if none has been written).
  """
  def info(block_id) do
    GenServer.call(via(block_id), :info)
  end

  @doc """
  Performs a loot roll for the block and returns the result.

  - Returns `{:found, %Item{}}` if the roll succeeds.
  - Returns `:nothing` if the roll fails.
  """
  def search(block_id) do
    GenServer.call(via(block_id), :search)
  end

  @doc """
  Writes `text` as the block's current scribble message, persists the change,
  and sends a success inbox message to `player_id`.

  Returns `:ok`.
  """
  def scribble(block_id, player_id, text) when is_binary(player_id) and is_binary(text) do
    GenServer.cast(via(block_id), {:scribble, player_id, text})
  end

  @doc """
  Returns the scribble surface description string for `block_id`, e.g. `"on the ground"`.
  """
  def scribble_surface_text(block_id) do
    GenServer.call(via(block_id), :scribble_surface_text)
  end

  @doc """
  Returns the registered process name atom for the block with the given `id`.
  """
  def process_name(id), do: :"block_#{id}"

  defp via(block_id), do: {process_name(block_id), UndercityServer.server_node()}

  # Server callbacks

  @doc false
  @impl true
  def init({id, name, type, exits, random}) do
    block =
      case Store.load_block(id) do
        {:ok, persisted} -> persisted
        :error -> CoreBlock.new(id, name, type, exits)
      end

    {:ok, {block, random}}
  end

  @doc false
  @impl true
  def handle_call({:join, player_id}, _from, {block, random}) do
    block = CoreBlock.add_person(block, player_id)
    Store.save_block(block.id, block)
    {:reply, block_info(block), {block, random}}
  end

  @doc false
  @impl true
  def handle_call({:leave, player_id}, _from, {block, random}) do
    block = CoreBlock.remove_person(block, player_id)
    Store.save_block(block.id, block)
    {:reply, :ok, {block, random}}
  end

  @doc false
  @impl true
  def handle_call({:has_person, player_id}, _from, {block, random}) do
    {:reply, CoreBlock.has_person?(block, player_id), {block, random}}
  end

  @doc false
  @impl true
  def handle_call(:info, _from, {block, random}) do
    {:reply, {block.id, CoreBlock.list_people(block), block.scribble}, {block, random}}
  end

  @doc false
  @impl true
  def handle_call(:search, _from, {block, random}) do
    {:reply, Search.search(block.type, random.()), {block, random}}
  end

  @doc false
  @impl true
  def handle_call(:scribble_surface_text, _from, {block, random}) do
    {:reply, scribble_surface(block.type), {block, random}}
  end

  @doc false
  @impl true
  def handle_cast({:scribble, player_id, text}, {block, random}) do
    block = CoreBlock.scribble(block, text)
    Store.save_block(block.id, block)
    PlayerInbox.success(player_id, "You scribble #{scribble_surface(block.type)}.")
    {:noreply, {block, random}}
  end

  defp block_info(block), do: {block.id, CoreBlock.list_people(block)}

  defp scribble_surface(:graveyard), do: "on a tombstone"
  defp scribble_surface(:space), do: "on the wall"
  defp scribble_surface(_), do: "on the ground"
end
