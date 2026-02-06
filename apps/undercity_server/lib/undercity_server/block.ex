defmodule UndercityServer.Block do
  @moduledoc """
  A GenServer that manages a Block in the undercity.
  """

  use GenServer

  alias UndercityCore.Block, as: CoreBlock
  alias UndercityCore.Person

  # Client API

  def start_link(opts) do
    id = Keyword.fetch!(opts, :id)
    name = Keyword.fetch!(opts, :name)
    description = Keyword.get(opts, :description)

    GenServer.start_link(__MODULE__, {id, name, description}, name: via(id))
  end

  def join(block_id, %Person{} = person) do
    GenServer.call(via(block_id), {:join, person})
  end

  def info(block_id) do
    GenServer.call(via(block_id), :info)
  end

  defp via(id) do
    {:via, Registry, {UndercityServer.Registry, {:block, id}}}
  end

  # Server callbacks

  @impl true
  def init({id, name, description}) do
    block = CoreBlock.new(id, name, description)
    {:ok, block}
  end

  @impl true
  def handle_call({:join, person}, _from, block) do
    block = CoreBlock.add_person(block, person)
    {:reply, :ok, block}
  end

  @impl true
  def handle_call(:info, _from, block) do
    info = %{
      id: block.id,
      name: block.name,
      description: block.description,
      people: CoreBlock.list_people(block)
    }

    {:reply, info, block}
  end
end
