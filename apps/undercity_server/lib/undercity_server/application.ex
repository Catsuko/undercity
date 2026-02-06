defmodule UndercityServer.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: UndercityServer.Registry},
      {UndercityServer.Block,
       id: "plaza",
       name: "The Plaza",
       description: "The central gathering place of the undercity."}
    ]

    opts = [strategy: :one_for_one, name: UndercityServer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
