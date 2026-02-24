defmodule UndercityCore.Player do
  @moduledoc """
  Pure domain model for a player character.

  Owns the intrinsic player state — identity, inventory, action points,
  and health — and exposes pure functions for each player action.

  Persistence and process lifecycle remain in `UndercityServer`.
  Block location is implicit in Block GenServers and is not tracked here.
  """

  alias UndercityCore.ActionPoints
  alias UndercityCore.Food
  alias UndercityCore.Health
  alias UndercityCore.Inventory
  alias UndercityCore.Item

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
  Attempts to exert the player: regenerates AP lazily, then spends `cost` AP.

  Returns `{:ok, player}` with updated action points, `{:error, :exhausted}` if
  the player lacks AP after regeneration, or `{:error, :collapsed}` if their HP
  has reached zero.
  """
  @spec exert(t(), pos_integer(), integer()) :: {:ok, t()} | {:error, :exhausted} | {:error, :collapsed}
  def exert(%__MODULE__{} = player, cost, now \\ System.os_time(:second)) do
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
