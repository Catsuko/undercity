defmodule UndercityServer.Player.Supervisor do
  @moduledoc """
  DynamicSupervisor that manages the lifecycle of per-player GenServer processes.

  - Starts `Player.Server` processes on demand when a player connects or reconnects
  - Unlike blocks, players are not pre-started at boot — they are added dynamically via `start_player/2`
  - Uses `:one_for_one` strategy; a crashed player process does not affect others
  """

  use DynamicSupervisor

  @doc """
  Starts the DynamicSupervisor and registers it as `UndercityServer.Player.Supervisor`.
  """
  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc false
  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a `Player.Server` process for the given `id` and `name` under this supervisor.

  - Returns `{:ok, pid}` on success.
  - Returns `{:error, {:already_started, pid}}` if a process for this player is already running.
  """
  def start_player(id, name) do
    DynamicSupervisor.start_child(
      {__MODULE__, UndercityServer.server_node()},
      {UndercityServer.Player.Server, id: id, name: name}
    )
  end
end
