defmodule UndercityServer.Actions.Scribble do
  @moduledoc """
  Handles scribbling messages on blocks.

  Sanitises the input text, consumes a use of chalk from the player's
  inventory, and writes the message to the block. Empty input after
  sanitisation is a no-op that does not consume chalk.
  """

  alias UndercityCore.Scribble
  alias UndercityCore.WorldMap
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Inbox, as: PlayerInbox

  @doc """
  Scribbles a sanitised message on `block_id` using one use of Chalk from the player's inventory.

  - Returns `{:ok, ap}` on success.
  - Returns `{:error, :empty_message}` if `text` is blank or contains only disallowed characters.
  - Returns `{:error, :item_missing}` if the player has no Chalk.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  def scribble(player_id, block_id, text) do
    case Scribble.sanitise(text) do
      :empty ->
        {:error, :empty_message}

      {:ok, sanitised} ->
        with {:ok, ap} <- Player.use_item(player_id, "Chalk", 1) do
          Block.scribble(block_id, sanitised)
          PlayerInbox.success(player_id, "You scribble #{scribble_surface(block_id)}.")
          {:ok, ap}
        end
    end
  end

  defp scribble_surface(block_id) do
    case WorldMap.block_type(block_id) do
      :graveyard -> "on a tombstone"
      :space -> "on the wall"
      _ -> "on the ground"
    end
  end
end
