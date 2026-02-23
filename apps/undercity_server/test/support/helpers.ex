defmodule UndercityServer.Test.Helpers do
  @moduledoc """
  Helpers for provisioning and cleaning up supervised processes and their
  persistent state in tests.
  """

  alias UndercityServer.Block.Supervisor, as: BlockSupervisor
  alias UndercityServer.Player.Server, as: PlayerServer

  @doc """
  Starts a Block under test supervision and registers cleanup of its DETS file
  on exit. Returns the block id.

  Options:
  - `:name` - block name (default: `"Test Block"`)
  - `:type` - block type atom (default: `:street`)
  - `:exits` - exits map (default: `%{}`)
  - `:random` - random function for loot rolls (optional)
  """
  def start_block!(opts \\ []) do
    id = "block_#{:erlang.unique_integer([:positive])}"
    name = Keyword.get(opts, :name, "Test Block")
    type = Keyword.get(opts, :type, :street)
    exits = Keyword.get(opts, :exits, %{})

    block_opts = %{id: id, name: name, type: type, exits: exits}

    block_opts =
      case Keyword.get(opts, :random) do
        nil -> block_opts
        random -> Map.put(block_opts, :random, random)
      end

    path = Path.join([File.cwd!(), UndercityServer.data_dir(), "blocks", "#{id}.dets"])
    ExUnit.Callbacks.on_exit(fn -> File.rm(path) end)
    ExUnit.Callbacks.start_supervised!({BlockSupervisor, block_opts}, id: id)

    id
  end

  @doc """
  Starts a Player under test supervision and registers cleanup of its DETS
  entry on exit. Returns the player id.

  Options:
  - `:name` - player name (default: `"Test Player"`)
  """
  def start_player!(opts \\ []) do
    id = "player_#{:erlang.unique_integer([:positive])}"
    name = Keyword.get(opts, :name, "Test Player")

    :dets.delete(:player_store, id)
    ExUnit.Callbacks.on_exit(fn -> :dets.delete(:player_store, id) end)
    ExUnit.Callbacks.start_supervised!({PlayerServer, id: id, name: name}, id: id)

    id
  end
end
