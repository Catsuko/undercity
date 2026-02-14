defmodule UndercityServer.Actions.Scribble do
  @moduledoc """
  Handles scribbling messages on blocks.

  Sanitises the input text, consumes a use of chalk from the player's
  inventory, and writes the message to the block. Empty input after
  sanitisation is a no-op that does not consume chalk.
  """

  alias UndercityCore.Scribble
  alias UndercityServer.Block
  alias UndercityServer.Player

  @doc """
  Scribbles a message on a block using chalk from the player's inventory.
  Returns `{:ok, ap}`, `{:error, :empty_message}`, `{:error, :item_missing}`, or `{:error, :exhausted}`.
  """
  def scribble(player_id, block_id, text) do
    case Scribble.sanitise(text) do
      :empty ->
        {:error, :empty_message}

      {:ok, sanitised} ->
        with {:ok, ap} <- Player.use_item(player_id, "Chalk", 1) do
          Block.scribble(block_id, sanitised)
          {:ok, ap}
        end
    end
  end
end
