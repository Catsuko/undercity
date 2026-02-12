defmodule UndercityServer.PlayerSupervisor do
  @moduledoc """
  DynamicSupervisor for player processes.
  """

  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a new Player process under this supervisor.
  """
  def start_player(id, name) do
    DynamicSupervisor.start_child(__MODULE__, {UndercityServer.Player, id: id, name: name})
  end
end
