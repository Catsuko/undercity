defmodule UndercityCore.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: UndercityCore.Server.Registry}
    ]

    opts = [strategy: :one_for_one, name: UndercityCore.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
