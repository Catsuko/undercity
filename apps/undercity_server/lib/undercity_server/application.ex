defmodule UndercityServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    block_children =
      Enum.map(UndercityCore.WorldMap.blocks(), fn block ->
        Supervisor.child_spec(
          {UndercityServer.Block.Supervisor, block},
          id: {:block, block.id}
        )
      end)

    children =
      [
        UndercityServer.Player.Store,
        UndercityServer.Player.Supervisor
      ] ++ block_children

    opts = [strategy: :one_for_one, name: UndercityServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
