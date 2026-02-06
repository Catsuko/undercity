defmodule UndercityServer.Gateway do
  @moduledoc """
  Entry point for people entering the undercity.
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
