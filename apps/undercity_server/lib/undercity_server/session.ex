defmodule UndercityServer.Session do
  @moduledoc """
  Manages player sessions: connecting to the server node, entering the world,
  and reconnecting existing players.

  Handles the connection lifecycle including retry logic with exponential
  backoff. New players are created and spawned at the default block; returning
  players are reconnected to whichever block they were last in.
  """

  alias UndercityCore.ActionPoints
  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Store, as: PlayerStore
  alias UndercityServer.Player.Supervisor, as: PlayerSupervisor
  alias UndercityServer.Vicinity

  @connect_retries 5
  @retry_rate 50

  @doc """
  Connects to the server node and enters the player into the world.
  Returns {:ok, block_info} on success or {:error, reason} on failure.
  """
  def connect(player_name) do
    server_node = UndercityServer.server_node()
    Node.connect(server_node)
    connect(player_name, @connect_retries)
  end

  defp connect(_player_name, 0), do: {:error, :server_not_found}

  defp connect(player_name, retries) do
    {player_id, vicinity, ap} = enter(player_name)
    {:ok, {player_id, vicinity, ap}}
  catch
    :exit, {:noproc, _} ->
      attempt = @connect_retries + 1 - retries
      (:math.pow(2, attempt) * @retry_rate) |> trunc() |> Process.sleep()
      connect(player_name, retries - 1)

    :exit, {{:nodedown, _}, _} ->
      {:error, :server_down}

    :exit, {{:noconnection, _}, _} ->
      {:error, :server_down}
  end

  @doc """
  Creates a new player and spawns them in the default block.
  Returns a tuple of {player_id, vicinity, constitution}.
  """
  def enter(name) when is_binary(name) do
    case PlayerStore.find_id_by_name(name) do
      {:ok, player_id} ->
        ensure_player_process(player_id, name)
        block_id = find_player_block(player_id)
        {player_id, Vicinity.build(block_id), Player.constitution(player_id)}

      :error ->
        player_id = generate_player_id()
        PlayerSupervisor.start_player(player_id, name)

        player_data = %{
          id: player_id,
          name: name,
          inventory: UndercityCore.Inventory.new(),
          action_points: ActionPoints.new()
        }

        PlayerStore.save(player_id, player_data)

        spawn_block = WorldMap.spawn_block()
        Block.join(spawn_block, player_id)
        {player_id, Vicinity.build(spawn_block), %{ap: ActionPoints.max()}}
    end
  end

  defp find_player_block(player_id) do
    Enum.find_value(WorldMap.blocks(), WorldMap.spawn_block(), fn block ->
      if Block.has_person?(block.id, player_id) do
        block.id
      end
    end)
  end

  defp generate_player_id do
    8 |> :crypto.strong_rand_bytes() |> Base.encode16(case: :lower)
  end

  defp ensure_player_process(player_id, name) do
    case PlayerSupervisor.start_player(player_id, name) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end
end
