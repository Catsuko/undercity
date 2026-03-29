defmodule UndercityServer.Block.Supervisor do
  @moduledoc """
  Supervises a block's Store and GenServer as a unit.

  Uses `:rest_for_one` strategy so that if the Store crashes, the Block
  process is also restarted (ensuring it re-reads persisted state). One
  instance per block in the world map, started statically at application boot.
  """

  use Elixir.Supervisor

  @doc """
  Starts the supervisor for a single block, launching its Store and GenServer as a unit.

  - `block` must be a map with `:id`, `:name`, `:type`, and `:exits` keys.
  - An optional `:random` key overrides the randomness source used during search rolls.
  """
  def start_link(block) do
    Supervisor.start_link(__MODULE__, block)
  end

  @doc false
  @impl true
  def init(block) do
    children = [
      {UndercityServer.Block.Store, block.id},
      {UndercityServer.Block,
       id: block.id,
       name: block.name,
       type: block.type,
       exits: block.exits,
       random: Map.get(block, :random, &:rand.uniform/0)}
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end
end
