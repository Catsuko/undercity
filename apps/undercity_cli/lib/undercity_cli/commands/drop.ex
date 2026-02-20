defmodule UndercityCli.Commands.Drop do
  @moduledoc """
  Handles drop commands (bare and indexed).
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.InventorySelector
  alias UndercityServer.Gateway

  def dispatch("drop", player_id, _vicinity, ap, hp) do
    case select_from_inventory(player_id, "Drop which item?") do
      :cancel -> {:acted, ap, hp}
      {:ok, index} -> drop(index, player_id, ap, hp)
    end
  end

  def dispatch({"drop", index_str}, player_id, _vicinity, ap, hp) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        drop(n - 1, player_id, ap, hp)

      _ ->
        MessageBuffer.warn("Invalid item selection.")
        {:acted, ap, hp}
    end
  end

  defp drop(index, player_id, ap, hp) do
    player_id
    |> Gateway.drop_item(index)
    |> Commands.handle_action(ap, hp, fn
      {:ok, item_name, new_ap} ->
        MessageBuffer.info("You dropped #{item_name}.")
        {:acted, new_ap, hp}

      {:error, :invalid_index} ->
        MessageBuffer.warn("Invalid item selection.")
        {:acted, ap, hp}
    end)
  end

  defp select_from_inventory(player_id, label) do
    player_id
    |> Gateway.check_inventory()
    |> InventorySelector.select(label)
  end
end
