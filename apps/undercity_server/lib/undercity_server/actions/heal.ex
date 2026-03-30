defmodule UndercityServer.Actions.Heal do
  @moduledoc """
  Resolves the heal action, restoring HP to a target player using a remedy item.

  - Validates the target is present in the block before consuming any resources
  - Validates the item at the given index is a known remedy
  - Consumes the remedy and spends AP atomically on the actor via `Player.use_item/3`
  - Applies HP restoration to the target and sends an inbox notification to the target if healing another player
  - Writes a typed inbox message to the actor describing the outcome
  """

  alias UndercityCore.Item.Remedy
  alias UndercityServer.Block
  alias UndercityServer.Player
  alias UndercityServer.Player.Inbox, as: PlayerInbox

  @ap_cost 1

  @doc """
  Executes a heal action from `player_id` targeting `target_id` using the item at `item_idx`.

  - Returns `{:ok, ap}` on success.
  - Returns `{:error, :invalid_target}` if the target is not present in the block.
  - Returns `{:error, :item_missing}` if no item exists at the given index.
  - Returns `{:error, :not_a_remedy}` if the item at that index is not a remedy.
  - Returns `{:error, :exhausted}` or `{:error, :collapsed}` if the actor cannot spend AP.
  """
  def heal(player_id, healer_name, target_name, block_id, target_id, item_idx) do
    with :ok <- validate_target(block_id, target_id),
         {:ok, item_name} <- find_remedy(player_id, item_idx),
         {:ok, new_ap} <- Player.use_item(player_id, item_idx, @ap_cost) do
      apply_heal(player_id, healer_name, target_name, target_id, item_name, new_ap)
    end
  end

  defp apply_heal(player_id, healer_name, target_name, target_id, item_name, new_ap) do
    {:heal, amount} = Remedy.effect(item_name)

    case Player.heal(target_id, amount, player_id, healer_name) do
      {:ok, healed} ->
        PlayerInbox.success(player_id, heal_message(player_id, target_id, target_name, healed))
        {:ok, new_ap}

      {:error, :invalid_target} ->
        {:error, :invalid_target}
    end
  end

  defp heal_message(same_id, same_id, _target_name, healed), do: "You healed yourself for #{healed}."
  defp heal_message(_player_id, _target_id, target_name, healed), do: "You healed #{target_name} for #{healed}."

  defp validate_target(block_id, target_id) do
    if Block.has_person?(block_id, target_id), do: :ok, else: {:error, :invalid_target}
  end

  defp find_remedy(player_id, item_idx) do
    case player_id |> Player.check_inventory() |> Enum.at(item_idx) do
      nil -> {:error, :item_missing}
      item -> if Remedy.remedy?(item.name), do: {:ok, item.name}, else: {:error, :not_a_remedy}
    end
  end
end
