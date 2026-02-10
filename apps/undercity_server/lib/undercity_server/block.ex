defmodule UndercityServer.Block do
  @moduledoc """
  A GenServer that manages a Block in the undercity.
  """

  use GenServer

  alias UndercityCore.Block, as: CoreBlock
  alias UndercityCore.Person
  alias UndercityServer.Store

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    type = Keyword.fetch!(opts, :type)
    exits = Keyword.get(opts, :exits, %{})

    GenServer.start_link(__MODULE__, {id, name, type, exits}, name: via(id))
  end

  def join(block_id, %Person{} = person) do
    GenServer.call(via(block_id), {:join, person})
  end

  def find_person(block_id, name) do
    GenServer.call(via(block_id), {:find_person, name})
  end

  def leave(block_id, %Person{} = person) do
    GenServer.call(via(block_id), {:leave, person})
  end

  def info(block_id) do
    GenServer.call(via(block_id), :info)
  end

  defp via(id) do
    {:via, Registry, {UndercityServer.Registry, {:block, id}}}
  end

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
  def handle_call({:join, person}, _from, block) do
    block = CoreBlock.add_person(block, person)
    Store.save_block(block.id, block)
    {:reply, :ok, block}
  end

  @impl true
  def handle_call({:leave, person}, _from, block) do
    block = CoreBlock.remove_person(block, person)
    Store.save_block(block.id, block)
    {:reply, :ok, block}
  end

  @impl true
  def handle_call({:find_person, name}, _from, block) do
    {:reply, CoreBlock.find_person_by_name(block, name), block}
  end

  @impl true
  def handle_call(:info, _from, block) do
    alias UndercityCore.WorldMap

    %{neighbourhood: neighbourhood, inside: inside} = WorldMap.block_context(block.id)

    info = %{
      id: block.id,
      name: block.name,
      type: block.type,
      people: CoreBlock.list_people(block),
      neighbourhood: neighbourhood,
      buildings: WorldMap.building_names(),
      inside: inside,
      building_type: WorldMap.building_type(block.id)
    }

    {:reply, info, block}
  end
end
