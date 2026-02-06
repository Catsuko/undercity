defmodule UndercityServer.Gateway do
  @moduledoc """
  Entry point for people entering the undercity.

  Gateway is the front door to the world — it handles routing people to their
  block when they first arrive or when they reconnect. It does not manage its
  own process; its functions run in the caller's process and coordinate with
  Block GenServers via the registry.
  """

  require Logger

  alias UndercityCore.Person
  alias UndercityCore.WorldMap
  alias UndercityServer.Block

  @doc """
  Creates a new person and spawns them in the default block.
  Returns info about the block they spawned in.
  """
  def enter(name) when is_binary(name) do
    spawn_block = WorldMap.spawn_block()

    case Block.find_person(spawn_block, name) do
      nil ->
        person = Person.new(name)
        :ok = Block.join(spawn_block, person)
        Logger.info("#{name} entered (#{spawn_block})")

      _existing ->
        Logger.info("#{name} reconnected (#{spawn_block})")
    end

    Block.info(spawn_block)
  end
end
