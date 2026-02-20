defmodule UndercityCli.Commands do
  @moduledoc """
  Command handlers for the CLI game.

  Each function calls the server via Gateway, pushes messages to the
  MessageBuffer, and returns the updated `{vicinity, ap, hp}` game state.
  Messages are rendered by the game loop after each dispatch.
  Threshold messages (AP/HP tier crossings) are handled by the game loop.
  """

  alias UndercityCli.MessageBuffer
  alias UndercityCli.View
  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.InventorySelector
  alias UndercityServer.Gateway

  def dispatch({:move, direction}, player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :move, direction)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, {:ok, new_vicinity}, new_ap} ->
        View.render_surroundings(new_vicinity)
        View.render_description(new_vicinity, player)
        {new_vicinity, new_ap, hp}

      {:ok, {:error, :no_exit}, new_ap} ->
        MessageBuffer.warn("You can't go that way.")
        {vicinity, new_ap, hp}
    end)
  end

  def dispatch(:search, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :search, nil)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, {:found, item}, new_ap} ->
        MessageBuffer.success("You found #{item.name}!")
        {vicinity, new_ap, hp}

      {:ok, {:found_but_full, item}, new_ap} ->
        MessageBuffer.warn("You found #{item.name}, but your inventory is full.")
        {vicinity, new_ap, hp}

      {:ok, :nothing, new_ap} ->
        MessageBuffer.warn("You find nothing.")
        {vicinity, new_ap, hp}
    end)
  end

  def dispatch(:inventory, _player, player_id, vicinity, ap, hp) do
    items = Gateway.check_inventory(player_id)

    case items do
      [] -> MessageBuffer.info("Your inventory is empty.")
      items -> MessageBuffer.info("Inventory: #{Enum.map_join(items, ", ", & &1.name)}")
    end

    {vicinity, ap, hp}
  end

  def dispatch(:drop, player, player_id, vicinity, ap, hp) do
    case select_from_inventory(player_id, "Drop which item?") do
      :cancel -> {vicinity, ap, hp}
      {:ok, index} -> dispatch({:drop, index}, player, player_id, vicinity, ap, hp)
    end
  end

  def dispatch({:drop, index}, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.drop_item(index)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, item_name, new_ap} ->
        MessageBuffer.info("You dropped #{item_name}.")
        {vicinity, new_ap, hp}

      {:error, :invalid_index} ->
        MessageBuffer.warn("Invalid item selection.")
        {vicinity, ap, hp}
    end)
  end

  def dispatch(:eat, player, player_id, vicinity, ap, hp) do
    case select_from_inventory(player_id, "Eat which item?") do
      :cancel -> {vicinity, ap, hp}
      {:ok, index} -> dispatch({:eat, index}, player, player_id, vicinity, ap, hp)
    end
  end

  def dispatch({:eat, index}, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :eat, index)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, item, _effect, new_ap, new_hp} ->
        MessageBuffer.success("Ate a #{item.name}.")
        {vicinity, new_ap, new_hp}

      {:error, :not_edible, item_name} ->
        MessageBuffer.warn("You can't eat #{item_name}.")
        {vicinity, ap, hp}

      {:error, :invalid_index} ->
        MessageBuffer.warn("Invalid item selection.")
        {vicinity, ap, hp}
    end)
  end

  def dispatch({:scribble, text}, _player, player_id, vicinity, ap, hp) do
    player_id
    |> Gateway.perform(vicinity.id, :scribble, text)
    |> handle_action(vicinity, ap, hp, fn
      {:ok, new_ap} ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(vicinity)}.")
        {vicinity, new_ap, hp}

      {:error, :empty_message} ->
        MessageBuffer.success("You scribble #{BlockDescription.scribble_surface(vicinity)}.")
        {vicinity, ap, hp}

      {:error, :item_missing} ->
        MessageBuffer.warn("You have no chalk.")
        {vicinity, ap, hp}
    end)
  end

  def dispatch(:quit, _player, _player_id, _vicinity, _ap, _hp), do: :quit

  def dispatch(:unknown, _player, _player_id, vicinity, ap, hp) do
    MessageBuffer.warn(
      "Unknown command. Try: search, inventory, drop [n], eat [n], scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit"
    )

    {vicinity, ap, hp}
  end

  defp select_from_inventory(player_id, label) do
    player_id
    |> Gateway.check_inventory()
    |> InventorySelector.select(label)
  end

  defp handle_action({:error, :exhausted}, vicinity, ap, hp, _callback) do
    MessageBuffer.warn("You are too exhausted to act.")
    {vicinity, ap, hp}
  end

  defp handle_action({:error, :collapsed}, vicinity, ap, hp, _callback) do
    MessageBuffer.warn("Your body has given out.")
    {vicinity, ap, hp}
  end

  defp handle_action(result, _vicinity, _ap, _hp, callback), do: callback.(result)
end
