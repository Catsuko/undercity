defmodule UndercityServer.Gateway do
  @moduledoc """
  Client SDK for the undercity game server.

  Gateway is the public API for interacting with the game world. It handles
  node connection, player routing, and movement by making GenServer calls
  to Block processes on the server node.
  """

  alias UndercityCore.Person
  alias UndercityCore.WorldMap
  alias UndercityServer.Block

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

    :exit, {:nodedown, _} ->
      {:error, :server_down}
  end

  @doc """
  Creates a new person and spawns them in the default block.
  Returns info about the block they spawned in.
  """
  def enter(name) when is_binary(name) do
    server_node = UndercityServer.server_node()

    case find_player_block(name, server_node) do
      {:ok, block_id} ->
        block_call(block_id, :info, server_node)

      :not_found ->
        spawn_block = WorldMap.spawn_block()
        person = Person.new(name)
        :ok = block_call(spawn_block, {:join, person}, server_node)
        block_call(spawn_block, :info, server_node)
    end
  end

  @doc """
  Moves a player in a given direction from their current block.
  Returns {:ok, block_info} on success or {:error, reason} on failure.
  """
  def move(player_name, direction, from_block_id) do
    server_node = UndercityServer.server_node()

    with {:ok, destination_id} <- resolve_exit(from_block_id, direction),
         {:ok, person} <- find_person(from_block_id, player_name, server_node) do
      :ok = block_call(from_block_id, {:leave, person}, server_node)
      :ok = block_call(destination_id, {:join, person}, server_node)
      {:ok, block_call(destination_id, :info, server_node)}
    end
  end

  defp block_call(block_id, message, server_node) do
    GenServer.call({Block.process_name(block_id), server_node}, message)
  end

  defp find_player_block(name, server_node) do
    Enum.find_value(WorldMap.blocks(), :not_found, fn block ->
      case block_call(block.id, {:find_person, name}, server_node) do
        nil -> false
        _person -> {:ok, block.id}
      end
    end)
  end

  defp resolve_exit(block_id, direction) do
    case WorldMap.resolve_exit(block_id, direction) do
      {:ok, _destination_id} = ok -> ok
      :error -> {:error, :no_exit}
    end
  end

  defp find_person(block_id, name, server_node) do
    case block_call(block_id, {:find_person, name}, server_node) do
      nil -> {:error, :not_found}
      person -> {:ok, person}
    end
  end
end
