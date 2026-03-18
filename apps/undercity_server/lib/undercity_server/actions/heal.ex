defmodule UndercityServer.Actions.Heal do
  @moduledoc """
  Handles the heal action.

  Routes self-heal through an atomic GenServer callback to avoid deadlock.
  Routes other-heal through sequential pre-checks, item consumption on the
  actor, and HP restoration on the target.
  """

  alias UndercityCore.Item.Remedy
  alias UndercityServer.Block
  alias UndercityServer.Player

  @ap_cost 1

  def heal(player_id, healer_name, block_id, target_id, item_idx) do
    with :ok <- validate_target(block_id, target_id),
         {:ok, item_name} <- find_remedy(player_id, item_idx),
         {:ok, new_ap} <- Player.use_item(player_id, item_idx, @ap_cost) do
      {:heal, amount} = Remedy.effect(item_name)

      case Player.heal(target_id, amount, player_id, healer_name) do
        {:ok, healed} ->
          {:ok, {:healed, target_id, new_ap, healed}}

        {:error, :invalid_target} ->
          {:error, :invalid_target}
      end
    end
  end

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
