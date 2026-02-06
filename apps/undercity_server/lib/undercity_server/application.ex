defmodule UndercityServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    UndercityServer.Store.start()

    spawn_block = find_block(UndercityCore.WorldMap.spawn_block())

    children = [
      {Registry, keys: :unique, name: UndercityServer.Registry},
      {UndercityServer.Block,
       id: spawn_block.id,
       name: spawn_block.name,
       description: spawn_block.description,
       exits: spawn_block.exits}
    ]

    opts = [strategy: :one_for_one, name: UndercityServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp find_block(id) do
    Enum.find(UndercityCore.WorldMap.blocks(), fn b -> b.id == id end)
  end

  @impl true
  def stop(_state) do
    UndercityServer.Store.stop()
  end
end
