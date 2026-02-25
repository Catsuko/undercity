defmodule UndercityServer.Test.Helpers do
  @moduledoc """
  Helpers for provisioning and cleaning up supervised processes and their
  persistent state in tests.
  """

  alias UndercityServer.Block
  alias UndercityServer.Block.Supervisor, as: BlockSupervisor
  alias UndercityServer.Gateway
  alias UndercityServer.Player.Server, as: PlayerServer
  alias UndercityServer.Player.Store, as: PlayerStore

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
  Returns a player ID string for use in tests that interact directly with
  lower-level APIs (Block, Player.Store, etc.).
  """
  def player_id, do: "player_#{:erlang.unique_integer([:positive])}"

  @doc """
  Returns a player name string for use in tests that enter the world via
  Gateway.
  """
  def player_name, do: "player_#{:erlang.unique_integer([:positive])}"

  @doc """
  Enters a player into the world via Gateway and registers cleanup of their
  DETS record on exit. Returns {player_id, vicinity, constitution}.
  """
  def enter_player!(name) do
    {player_id, vicinity, constitution} = Gateway.enter(name)
    ExUnit.Callbacks.on_exit(fn -> cleanup_player(player_id) end)
    {player_id, vicinity, constitution}
  end

  defp cleanup_player(player_id) do
    case PlayerStore.load(player_id) do
      {:ok, data} ->
        if block_id = Map.get(data, :block_id), do: Block.leave(block_id, player_id)

      :error ->
        :ok
    end

    :dets.delete(:player_store, player_id)
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
