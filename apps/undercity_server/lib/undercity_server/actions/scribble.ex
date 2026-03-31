defmodule UndercityServer.Actions.Scribble do
  @moduledoc """
  Handles scribbling messages on blocks.

  Sanitises the input text, consumes a use of chalk from the player's
  inventory, and writes the message to the block. Empty input after
  sanitisation is a no-op that does not consume chalk or AP.
  """

  alias UndercityCore.Scribble
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Inbox, as: PlayerInbox

  @doc """
  Scribbles a sanitised message on `block_id` using one use of Chalk from the player's inventory.

  - Returns `{:ok, ap}` on success.
  - Returns `{:ok, ap}` unchanged if `text` is blank or the player has no Chalk (inbox message written).
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the player cannot spend AP.
  """
  def scribble(player_id, block_id, text) do
    case Scribble.sanitise(text) do
      :empty ->
        PlayerInbox.success(player_id, "You scribble #{Block.scribble_surface_text(block_id)}.")
        {:ok, Player.constitution(player_id).ap}

      {:ok, sanitised} ->
        case Player.use_item(player_id, "Chalk", 1) do
          {:ok, ap} ->
            Block.scribble(block_id, player_id, sanitised)
            {:ok, ap}

          {:error, :item_missing} ->
            PlayerInbox.failure(player_id, "You have no chalk.")
            {:ok, Player.constitution(player_id).ap}

          {:error, _} = error ->
            error
        end
    end
  end
end
