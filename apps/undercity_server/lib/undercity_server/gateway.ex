defmodule UndercityServer.Gateway do
  @moduledoc """
  Client SDK for the undercity game server.

  Gateway is the public API for interacting with the game world. It handles
  node connection, player routing, and movement by making GenServer calls
  to Block processes on the server node.
  """

  alias UndercityCore.Scribble
  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.PlayerIdentity
  alias UndercityServer.PlayerStore
  alias UndercityServer.PlayerSupervisor
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
    {:ok, enter(player_name)}
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
  Returns a tuple of {player_id, vicinity}.
  """
  def enter(name) when is_binary(name) do
    server_node = UndercityServer.server_node()

    case server_call(PlayerStore, {:find_id_by_name, name}, server_node) do
      {:ok, player_id} ->
        ensure_player_process(player_id, name, server_node)
        block_id = find_player_block(player_id, server_node)
        {player_id, build_vicinity(block_id, server_node)}

      :error ->
        player_id = PlayerIdentity.generate_id()
        start_player(player_id, name, server_node)

        player_data = %{id: player_id, name: name, inventory: UndercityCore.Inventory.new()}
        server_call(PlayerStore, {:save, player_id, player_data}, server_node)

        spawn_block = WorldMap.spawn_block()
        {^spawn_block, _player_ids} = block_call(spawn_block, {:join, player_id}, server_node)
        {player_id, build_vicinity(spawn_block, server_node)}
    end
  end

  @doc """
  Moves a player in a given direction from their current block.
  Returns {:ok, vicinity} on success or {:error, reason} on failure.
  """
  def move(player_id, direction, from_block_id) do
    server_node = UndercityServer.server_node()

    with {:ok, destination_id} <- resolve_exit(from_block_id, direction),
         true <- block_call(from_block_id, {:has_person, player_id}, server_node) do
      :ok = block_call(from_block_id, {:leave, player_id}, server_node)
      {^destination_id, _player_ids} = block_call(destination_id, {:join, player_id}, server_node)
      {:ok, build_vicinity(destination_id, server_node)}
    else
      false -> {:error, :not_found}
      {:error, _} = error -> error
    end
  end

  @doc """
  Performs a search action for the given player in the given block.
  Returns {:found, item} or :nothing.
  """
  def search(player_id, block_id) do
    server_node = UndercityServer.server_node()

    case block_call(block_id, :search, server_node) do
      {:found, item} ->
        GenServer.cast({PlayerIdentity.via(player_id), server_node}, {:add_item, item})
        {:found, item}

      :nothing ->
        :nothing
    end
  end

  @doc """
  Scribbles a message on a block using chalk from the player's inventory.
  Returns :ok, {:error, :no_chalk}, or {:error, :invalid, reason}.
  """
  def scribble(player_id, block_id, text) do
    case Scribble.sanitise(text) do
      :empty ->
        :ok

      {:ok, sanitised} ->
        server_node = UndercityServer.server_node()

        case player_call(player_id, {:use_item, "Chalk"}, server_node) do
          :not_found ->
            {:error, :no_chalk}

          {:ok, _item} ->
            block_call(block_id, {:scribble, sanitised}, server_node)
            :ok
        end
    end
  end

  @doc """
  Returns the player's current inventory items.
  """
  def get_inventory(player_id) do
    server_node = UndercityServer.server_node()
    player_call(player_id, :get_inventory, server_node)
  end

  defp build_vicinity(block_id, server_node) do
    {^block_id, player_ids} = block_call(block_id, :info, server_node)
    names = server_call(PlayerStore, {:get_names, player_ids}, server_node)
    scribble = block_call(block_id, :get_scribble, server_node)

    people =
      Enum.map(player_ids, fn id ->
        %{id: id, name: Map.get(names, id, "Unknown")}
      end)

    Vicinity.new(block_id, people, scribble: scribble)
  end

  defp block_call(block_id, message, server_node) do
    GenServer.call({Block.process_name(block_id), server_node}, message)
  end

  defp server_call(module, message, server_node) do
    GenServer.call({module, server_node}, message)
  end

  defp player_call(player_id, message, server_node) do
    GenServer.call({PlayerIdentity.via(player_id), server_node}, message)
  end

  defp start_player(player_id, name, server_node) do
    DynamicSupervisor.start_child(
      {PlayerSupervisor, server_node},
      {UndercityServer.Player, id: player_id, name: name}
    )
  end

  defp find_player_block(player_id, server_node) do
    Enum.find_value(WorldMap.blocks(), WorldMap.spawn_block(), fn block ->
      if block_call(block.id, {:has_person, player_id}, server_node) do
        block.id
      end
    end)
  end

  defp resolve_exit(block_id, direction) do
    case WorldMap.resolve_exit(block_id, direction) do
      {:ok, _destination_id} = ok -> ok
      :error -> {:error, :no_exit}
    end
  end

  defp ensure_player_process(player_id, name, server_node) do
    case start_player(player_id, name, server_node) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end
  end
end
