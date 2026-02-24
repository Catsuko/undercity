defmodule UndercityServer.Gateway do
  @moduledoc """
  Public API for interacting with the game server.

  Gateway is a thin facade that delegates to domain modules. Player actions
  route through `perform/4`, which dispatches to the appropriate Actions
  module. To add a new action: implement it in an Actions module, then add
  a `perform` clause here.
  """

  alias UndercityServer.Actions
  alias UndercityServer.Block

  defdelegate connect(player_name), to: UndercityServer.Session
  defdelegate enter(name), to: UndercityServer.Session
  defdelegate check_inventory(player_id), to: UndercityServer.Player
  defdelegate drop_item(player_id, index), to: UndercityServer.Player

  def perform(player_id, _block_id, :eat, index), do: Actions.Eat.eat(player_id, index)

  def perform(player_id, block_id, action, args) do
    if Block.has_person?(block_id, player_id) do
      dispatch(player_id, block_id, action, args)
    else
      {:error, :not_in_block}
    end
  end

  defp dispatch(player_id, block_id, :move, direction), do: Actions.Movement.move(player_id, block_id, direction)
  defp dispatch(player_id, block_id, :search, _args), do: Actions.Search.search(player_id, block_id)
  defp dispatch(player_id, block_id, :scribble, text), do: Actions.Scribble.scribble(player_id, block_id, text)

  defp dispatch(player_id, _block_id, :attack, {target_name, index}) do
    weapon_name = player_id |> UndercityServer.Player.check_inventory() |> Enum.at(index) |> then(&(&1 && &1.name))
    {:miss, target_name, weapon_name}
  end
end
