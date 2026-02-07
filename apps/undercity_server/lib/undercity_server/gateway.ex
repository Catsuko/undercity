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

  @doc """
  Moves a player in a given direction from their current block.
  Returns {:ok, block_info} on success or {:error, reason} on failure.
  """
  def move(player_name, direction, from_block_id) do
    with {:ok, destination_id} <- resolve_exit(from_block_id, direction),
         {:ok, person} <- find_person(from_block_id, player_name) do
      :ok = Block.leave(from_block_id, person)
      :ok = Block.join(destination_id, person)
      Logger.info("#{player_name} moved #{direction} to #{destination_id}")
      {:ok, Block.info(destination_id)}
    end
  end

  defp resolve_exit(block_id, direction) do
    info = Block.info(block_id)

    case List.keyfind(info.exits, direction, 0) do
      {_, destination_id} -> {:ok, destination_id}
      nil -> {:error, :no_exit}
    end
  end

  defp find_person(block_id, name) do
    case Block.find_person(block_id, name) do
      nil -> {:error, :not_found}
      person -> {:ok, person}
    end
  end
end
