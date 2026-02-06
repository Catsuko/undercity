defmodule UndercityServer.Gateway do
  @moduledoc """
  Entry point for people entering the undercity.

  Gateway is the front door to the world — it handles routing people to their
  block when they first arrive or when they reconnect. It does not manage its
  own process; its functions run in the caller's process and coordinate with
  Block GenServers via the registry.
  """

  alias UndercityCore.Person
  alias UndercityServer.Block

  @spawn_block "plaza"

  @doc """
  Creates a new person and spawns them in the default block.
  Returns info about the block they spawned in.
  """
  def enter(name) when is_binary(name) do
    person = Person.new(name)
    :ok = Block.join(@spawn_block, person)
    Block.info(@spawn_block)
  end
end
