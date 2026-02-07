defmodule UndercityServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    UndercityServer.Store.start()

    block_children =
      Enum.map(UndercityCore.WorldMap.blocks(), fn block ->
        Supervisor.child_spec(
          {UndercityServer.Block,
           id: block.id,
           name: block.name,
           description: block.description,
           exits: block.exits},
          id: {:block, block.id}
        )
      end)

    children = [
      {Registry, keys: :unique, name: UndercityServer.Registry}
      | block_children
    ]

    opts = [strategy: :one_for_one, name: UndercityServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def stop(_state) do
    UndercityServer.Store.stop()
  end
end
