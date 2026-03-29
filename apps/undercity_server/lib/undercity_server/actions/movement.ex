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
  Moves a player one step in `direction` from `from_block_id`.

  - Returns `{:ok, vicinity, ap}` where `vicinity` describes the destination block.
  - Returns `{:error, :no_exit}` if the direction has no exit from the current block.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  def move(player_id, from_block_id, direction) do
    Player.perform(player_id, fn ->
      with {:ok, destination_id} <- resolve_exit(from_block_id, direction) do
        :ok = Block.leave(from_block_id, player_id)
        :ok = Player.move_to(player_id, destination_id)
        Block.join(destination_id, player_id)
        {:ok, Vicinity.build(destination_id)}
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
