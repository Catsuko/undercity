defmodule UndercityServer.Session do
  @moduledoc """
  Manages the player connection lifecycle — initial connect, world entry, and reconnection.

  - Attempts to connect to the server node with up to 5 retries using exponential backoff
  - Creates new players at the spawn block on first entry
  - Reconnects returning players to their last known block, scanning all blocks if presence records are stale
  """

  alias UndercityCore.ActionPoints
  alias UndercityCore.Health
  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Store, as: PlayerStore
  alias UndercityServer.Player.Supervisor, as: PlayerSupervisor
  alias UndercityServer.Vicinity

  @connect_retries 5
  @retry_rate 50

  @doc """
  Connects to the server node and enters `player_name` into the world.

  - Returns `{:ok, {player_id, vicinity, constitution}}` on success.
  - Returns `{:error, :server_not_found}` if the node cannot be reached after all retries.
  - Returns `{:error, :server_down}` if the node is unreachable.
  - Returns `{:error, :invalid_name}` if the name contains disallowed characters.
  """
  def connect(player_name) do
    server_node = UndercityServer.server_node()
    Node.connect(server_node)
    connect(player_name, @connect_retries)
  end

  defp connect(_player_name, 0), do: {:error, :server_not_found}

  defp connect(player_name, retries) do
    case enter(player_name) do
      {:error, :invalid_name} -> {:error, :invalid_name}
      result -> {:ok, result}
    end
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
  Enters `name` into the world, creating the player record if this is their first login.

  - Returns `{player_id, vicinity, constitution}` for both new and returning players.
  - Returns `{:error, :invalid_name}` if the name contains characters outside `[a-zA-Z0-9]`.
  - Side effect: starts the player's GenServer process, joins them to the appropriate block.
  """
  def enter(name) when is_binary(name) do
    case PlayerStore.find_id_by_name(name) do
      {:ok, player_id} ->
        ensure_player_process(player_id, name)
        block_id = find_player_block(player_id)
        {player_id, Vicinity.build(block_id), Player.constitution(player_id)}

      :error ->
        player_id = generate_player_id()

        player_data = %{
          id: player_id,
          name: name,
          inventory: UndercityCore.Inventory.new(),
          action_points: ActionPoints.new(),
          health: Health.new()
        }

        case PlayerStore.register(player_id, player_data) do
          :ok ->
            PlayerSupervisor.start_player(player_id, name)
            spawn_block = WorldMap.spawn_block()
            Block.join(spawn_block, player_id)
            Player.move_to(player_id, spawn_block)
            {player_id, Vicinity.build(spawn_block), %{ap: ActionPoints.max(), hp: Health.max()}}

          {:error, :invalid_name} ->
            {:error, :invalid_name}
        end
    end
  end

  defp find_player_block(player_id) do
    case Player.location(player_id) do
      nil ->
        spawn_block = WorldMap.spawn_block()
        Block.join(spawn_block, player_id)
        Player.move_to(player_id, spawn_block)
        spawn_block

      block_id ->
        if Block.has_person?(block_id, player_id) do
          block_id
        else
          scan_or_restore(player_id, block_id)
        end
    end
  end

  defp scan_or_restore(player_id, block_id) do
    found =
      Enum.find_value(WorldMap.blocks(), fn block ->
        if Block.has_person?(block.id, player_id), do: block.id
      end)

    case found do
      nil ->
        Block.join(block_id, player_id)
        block_id

      actual_id ->
        actual_id
    end
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
