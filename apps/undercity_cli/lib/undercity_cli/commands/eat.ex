defmodule UndercityCli.Commands.Eat do
  @moduledoc """
  Handles eat commands (bare and indexed).
  """

  alias UndercityCli.Commands
  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.InventorySelector
  alias UndercityServer.Gateway

  def dispatch("eat", player_id, vicinity, ap, hp) do
    case select_from_inventory(player_id, "Eat which item?") do
      :cancel -> {:acted, ap, hp}
      {:ok, index} -> eat(index, player_id, vicinity, ap, hp)
    end
  end

  def dispatch({"eat", index_str}, player_id, vicinity, ap, hp) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 ->
        eat(n - 1, player_id, vicinity, ap, hp)

      _ ->
        MessageBuffer.warn("Invalid item selection.")
        {:acted, ap, hp}
    end
  end

  defp eat(index, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :eat, index)
    |> Commands.handle_action(ap, hp, fn
      {:ok, item, _effect, new_ap, new_hp} ->
        MessageBuffer.success("Ate a #{item.name}.")
        {:acted, new_ap, new_hp}

      {:error, :not_edible, item_name} ->
        MessageBuffer.warn("You can't eat #{item_name}.")
        {:acted, ap, hp}

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
