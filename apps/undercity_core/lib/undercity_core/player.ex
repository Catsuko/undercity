defmodule UndercityCore.Player do
  @moduledoc """
  Pure domain model for a player character.

  Owns the intrinsic player state — identity, inventory, action points,
  and health — and exposes pure functions for each player action.

  Persistence and process lifecycle remain in `UndercityServer`.
  Block location is implicit in Block GenServers and is not tracked here.
  """

  alias UndercityCore.ActionPoints
  alias UndercityCore.Health
  alias UndercityCore.Inventory
  alias UndercityCore.Item
  alias UndercityCore.Item.Food

  defstruct [:id, :name, :inventory, :action_points, :health]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          inventory: Inventory.t(),
          action_points: ActionPoints.t(),
          health: Health.t()
        }

  @doc """
  Returns a fresh player struct with a full inventory, maximum AP, and maximum HP.
  """
  @spec new(String.t(), String.t()) :: t()
  def new(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      inventory: Inventory.new(),
      action_points: ActionPoints.new(),
      health: Health.new()
    }
  end

  @doc """
  Regenerates AP lazily then attempts to spend AP.

  Accepts either a `pos_integer()` cost or an `atom()` action name.
  When an action atom is given, the cost is currently hardcoded to 1;
  the action is reserved for future AP cost mapping per action type.

  - Returns `{:ok, player}` with updated action points
  - Returns `{:error, :exhausted}` if the player lacks AP after regeneration
  - Returns `{:error, :collapsed}` if the player's HP is zero
  """
  @spec exert(t(), pos_integer() | atom(), integer()) ::
          {:ok, t()} | {:error, :exhausted} | {:error, :collapsed}
  def exert(player, cost_or_action, now \\ System.os_time(:second))

  def exert(%__MODULE__{} = player, action, now) when is_atom(action) do
    exert(player, 1, now)
  end

  def exert(%__MODULE__{} = player, cost, now) do
    if Health.current(player.health) == 0 do
      {:error, :collapsed}
    else
      action_points = ActionPoints.regenerate(player.action_points, now)

      case ActionPoints.spend(action_points, cost, now) do
        {:ok, action_points} -> {:ok, %{player | action_points: action_points}}
        {:error, :exhausted} -> {:error, :exhausted}
      end
    end
  end

  @doc """
  Attempts to use an item by atom id, spending the AP needed for that item
  and consuming a use if the item is consumable.

  Validates item existence before spending AP. The item is removed from the
  inventory if its last use is spent.

  - Returns `{:ok, player}` on success
  - Returns `{:error, :item_missing}` if no item with the given id is in the inventory
  - Returns `{:error, :exhausted}` if the player lacks AP (item use not consumed)
  - Returns `{:error, :collapsed}` if the player's HP is zero (item use not consumed)
  """
  @spec exert_using(t(), atom(), integer()) ::
          {:ok, t()} | {:error, :item_missing} | {:error, :exhausted} | {:error, :collapsed}
  def exert_using(%__MODULE__{} = player, item_id, now \\ System.os_time(:second)) when is_atom(item_id) do
    with {:ok, updated_inventory} <- Inventory.use_item(player.inventory, item_id),
         {:ok, player} <- exert(player, item_id, now) do
      {:ok, %{player | inventory: updated_inventory}}
    end
  end

  @doc """
  Drops the item at `index` from the player's inventory, spending 1 AP.

  Returns `{:ok, player, item_name}` on success, or an error:
  - `{:error, :invalid_index}` — index is out of bounds
  - `{:error, :exhausted}` — not enough AP
  - `{:error, :collapsed}` — player HP is zero
  """
  @spec drop(t(), non_neg_integer(), integer()) ::
          {:ok, t(), String.t()} | {:error, :invalid_index} | {:error, :exhausted} | {:error, :collapsed}
  def drop(%__MODULE__{} = player, index, now \\ System.os_time(:second)) do
    items = Inventory.list_items(player.inventory)

    with {:index, true} <- {:index, index >= 0 and index < length(items)},
         {:ok, player} <- exert(player, 1, now) do
      item_name = Enum.at(items, index).name
      {:ok, %{player | inventory: Inventory.remove_at(player.inventory, index)}, item_name}
    else
      {:index, false} -> {:error, :invalid_index}
      {:error, _} = error -> error
    end
  end

  @doc """
  Eats the item at `index` from the player's inventory, spending 1 AP and
  applying the food's health effect.

  Returns `{:ok, player, item, effect}` on success, or an error:
  - `{:error, :invalid_index}` — index is out of bounds
  - `{:error, :not_edible, item_name}` — item is not food
  - `{:error, :exhausted}` — not enough AP
  - `{:error, :collapsed}` — player HP is zero
  """
  @spec eat(t(), non_neg_integer(), integer()) ::
          {:ok, t(), Item.t(), {:heal, pos_integer()} | {:damage, pos_integer()}}
          | {:error, :invalid_index}
          | {:error, :not_edible, String.t()}
          | {:error, :exhausted}
          | {:error, :collapsed}
  def eat(%__MODULE__{} = player, index, now \\ System.os_time(:second)) do
    items = Inventory.list_items(player.inventory)

    with {:index, true} <- {:index, index >= 0 and index < length(items)},
         item = Enum.at(items, index),
         {:edible, effect} when effect != :not_edible <- {:edible, Food.effect(item.name)},
         {:ok, player} <- exert(player, 1, now) do
      player = %{
        player
        | inventory: Inventory.remove_at(player.inventory, index),
          health: Health.apply_effect(player.health, effect)
      }

      {:ok, player, item, effect}
    else
      {:index, false} -> {:error, :invalid_index}
      {:edible, :not_edible} -> {:error, :not_edible, Enum.at(items, index).name}
      {:error, _} = error -> error
    end
  end
end
