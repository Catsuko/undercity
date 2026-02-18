defmodule UndercityCli.Commands do
  @moduledoc """
  Command handlers for the CLI game.

  Each function calls the server via Gateway, pushes messages to the
  MessageBuffer, and returns the updated `{vicinity, ap, hp}` game state.
  Messages are rendered by the game loop after each dispatch.
  """

  alias UndercityCli.MessageBuffer
  alias UndercityCli.View
  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Constitution
  alias UndercityServer.Gateway

  def dispatch({:move, direction}, player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :move, direction)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, {:ok, new_vicinity}, new_ap} ->
        View.render_surroundings(new_vicinity)
        View.render_description(new_vicinity, player)
        MessageBuffer.push(Constitution.threshold_messages(ap, new_ap, hp, hp))
        {new_vicinity, new_ap, hp}

      {:ok, {:error, :no_exit}, new_ap} ->
        MessageBuffer.push([{"You can't go that way.", :warning} | Constitution.threshold_messages(ap, new_ap, hp, hp)])
        {vicinity, new_ap, hp}
    end)
  end

  def dispatch(:search, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :search, nil)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, {:found, item}, new_ap} ->
        MessageBuffer.push([{"You found #{item.name}!", :success} | Constitution.threshold_messages(ap, new_ap, hp, hp)])
        {vicinity, new_ap, hp}

      {:ok, {:found_but_full, item}, new_ap} ->
        MessageBuffer.push([
          {"You found #{item.name}, but your inventory is full.", :warning}
          | Constitution.threshold_messages(ap, new_ap, hp, hp)
        ])

        {vicinity, new_ap, hp}

      {:ok, :nothing, new_ap} ->
        MessageBuffer.push([{"You find nothing.", :warning} | Constitution.threshold_messages(ap, new_ap, hp, hp)])
        {vicinity, new_ap, hp}
    end)
  end

  def dispatch(:inventory, _player, player_id, vicinity, ap, hp) do
    items = Gateway.check_inventory(player_id)

    message =
      case items do
        [] -> {"Your inventory is empty.", :info}
        items -> {"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info}
      end

    MessageBuffer.push([message])
    {vicinity, ap, hp}
  end

  def dispatch({:drop, index}, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.drop_item(index)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, item_name, new_ap} ->
        MessageBuffer.push([{"You dropped #{item_name}.", :info} | Constitution.threshold_messages(ap, new_ap, hp, hp)])
        {vicinity, new_ap, hp}

      {:error, :invalid_index} ->
        MessageBuffer.push("Invalid item selection.", :warning)
        {vicinity, ap, hp}
    end)
  end

  def dispatch({:eat, index}, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :eat, index)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, item, _effect, new_ap, new_hp} ->
        MessageBuffer.push([{"Ate a #{item.name}.", :success} | Constitution.threshold_messages(ap, new_ap, hp, new_hp)])
        {vicinity, new_ap, new_hp}

      {:error, :not_edible, item_name} ->
        MessageBuffer.push("You can't eat #{item_name}.", :warning)
        {vicinity, ap, hp}

      {:error, :invalid_index} ->
        MessageBuffer.push("Invalid item selection.", :warning)
        {vicinity, ap, hp}
    end)
  end

  def dispatch({:scribble, text}, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :scribble, text)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, new_ap} ->
        MessageBuffer.push([
          {"You scribble #{BlockDescription.scribble_surface(vicinity)}.", :success}
          | Constitution.threshold_messages(ap, new_ap, hp, hp)
        ])

        {vicinity, new_ap, hp}

      {:error, :empty_message} ->
        MessageBuffer.push("You scribble #{BlockDescription.scribble_surface(vicinity)}.", :success)
        {vicinity, ap, hp}

      {:error, :item_missing} ->
        MessageBuffer.push("You have no chalk.", :warning)
        {vicinity, ap, hp}
    end)
  end

  def dispatch(:quit, _player, _player_id, _vicinity, _ap, _hp), do: :quit

  def dispatch(:unknown, _player, _player_id, vicinity, ap, hp) do
    MessageBuffer.push(
      "Unknown command. Try: search, inventory, drop <n>, eat <n>, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
      :warning
    )

    {vicinity, ap, hp}
  end

  defp handle_action({:error, :exhausted}, vicinity, ap, hp, _callback) do
    MessageBuffer.push("You are too exhausted to act.", :warning)
    {vicinity, ap, hp}
  end

  defp handle_action({:error, :collapsed}, vicinity, ap, hp, _callback) do
    MessageBuffer.push("Your body has given out.", :warning)
    {vicinity, ap, hp}
  end

  defp handle_action(result, _vicinity, _ap, _hp, callback), do: callback.(result)
end
