defmodule UndercityServer.Actions.Movement do
  @moduledoc """
  Handles player movement between blocks.

  Orchestrates the multi-step process of leaving one block and joining
  another, including exit resolution and presence validation. This logic
  lives here rather than in Block because movement spans two blocks.
  """

  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Vicinity

  @doc """
  Moves a player in a given direction from their current block.
  Returns `{:ok, result, ap}` or `{:error, :exhausted}`.
  """
  def move(player_id, direction, from_block_id) do
    Player.perform(player_id, fn ->
      with {:ok, destination_id} <- resolve_exit(from_block_id, direction),
           true <- Block.has_person?(from_block_id, player_id) do
        :ok = Block.leave(from_block_id, player_id)
        Block.join(destination_id, player_id)
        {:ok, Vicinity.build(destination_id)}
      else
        false -> {:error, :not_found}
        {:error, _} = error -> error
      end
    end)
  end

  defp resolve_exit(block_id, direction) do
    case WorldMap.resolve_exit(block_id, direction) do
      {:ok, _destination_id} = ok -> ok
      :error -> {:error, :no_exit}
    end
  end
end
