defmodule UndercityCli.Commands do
  @moduledoc """
  Command handlers for the CLI game.

  Each function calls the server via Gateway, renders the result, and returns
  the updated `{vicinity, ap, hp}` game state.
  """

  alias UndercityCli.View
  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Constitution
  alias UndercityServer.Gateway

  @inability_messages %{
    exhausted: {"You are too exhausted to act.", :warning},
    collapsed: {"Your body has given out.", :warning}
  }

  def dispatch({:move, direction}, player, player_id, vicinity, ap, hp) do
    move(player, player_id, vicinity, ap, hp, direction)
  end

  def dispatch(:search, player, player_id, vicinity, ap, hp) do
    search(player, player_id, vicinity, ap, hp)
  end

  def dispatch(:inventory, player, player_id, vicinity, ap, hp) do
    inventory(player, player_id, vicinity, ap, hp)
  end

  def dispatch({:drop, index}, player, player_id, vicinity, ap, hp) do
    drop(player, player_id, vicinity, ap, hp, index)
  end

  def dispatch({:eat, index}, player, player_id, vicinity, ap, hp) do
    eat(player, player_id, vicinity, ap, hp, index)
  end

  def dispatch({:scribble, text}, player, player_id, vicinity, ap, hp) do
    scribble(player, player_id, vicinity, ap, hp, text)
  end

  def dispatch(:quit, _player, _player_id, _vicinity, _ap, _hp), do: :quit

  def dispatch(:unknown, player, _player_id, vicinity, ap, hp) do
    unknown(player, vicinity, ap, hp)
  end

  def move(player, player_id, vicinity, ap, hp, direction) do
    case Gateway.perform(player_id, vicinity.id, :move, direction) do
      {:ok, {:ok, new_vicinity}, new_ap} ->
        View.render(new_vicinity, player, Constitution.threshold_messages(ap, new_ap, hp, hp))
        {new_vicinity, new_ap, hp}

      {:ok, {:error, :no_exit}, new_ap} ->
        messages = [{"You can't go that way.", :warning} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
        View.render(vicinity, player, messages)
        {vicinity, new_ap, hp}

      {:error, reason} ->
        View.render(vicinity, player, [inability_message(reason)])
        {vicinity, ap, hp}
    end
  end

  def search(player, player_id, vicinity, ap, hp) do
    case Gateway.perform(player_id, vicinity.id, :search, nil) do
      {:ok, {:found, item}, new_ap} ->
        messages = [{"You found #{item.name}!", :success} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
        View.render(vicinity, player, messages)
        {vicinity, new_ap, hp}

      {:ok, {:found_but_full, item}, new_ap} ->
        messages = [
          {"You found #{item.name}, but your inventory is full.", :warning}
          | Constitution.threshold_messages(ap, new_ap, hp, hp)
        ]

        View.render(vicinity, player, messages)
        {vicinity, new_ap, hp}

      {:ok, :nothing, new_ap} ->
        messages = [{"You find nothing.", :warning} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
        View.render(vicinity, player, messages)
        {vicinity, new_ap, hp}

      {:error, reason} ->
        View.render(vicinity, player, [inability_message(reason)])
        {vicinity, ap, hp}
    end
  end

  def inventory(player, player_id, vicinity, ap, hp) do
    items = Gateway.check_inventory(player_id)

    message =
      case items do
        [] -> {"Your inventory is empty.", :info}
        items -> {"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info}
      end

    View.render(vicinity, player, [message])
    {vicinity, ap, hp}
  end

  def drop(player, player_id, vicinity, ap, hp, index) do
    case Gateway.drop_item(player_id, index) do
      {:ok, item_name, new_ap} ->
        messages = [{"You dropped #{item_name}.", :info} | Constitution.threshold_messages(ap, new_ap, hp, hp)]
        View.render(vicinity, player, messages)
        {vicinity, new_ap, hp}

      {:error, :invalid_index} ->
        View.render(vicinity, player, [{"Invalid item selection.", :warning}])
        {vicinity, ap, hp}

      {:error, reason} ->
        View.render(vicinity, player, [inability_message(reason)])
        {vicinity, ap, hp}
    end
  end

  def eat(player, player_id, vicinity, ap, hp, index) do
    case Gateway.perform(player_id, vicinity.id, :eat, index) do
      {:ok, item, _effect, new_ap, new_hp} ->
        messages = [{"Ate a #{item.name}.", :success} | Constitution.threshold_messages(ap, new_ap, hp, new_hp)]
        View.render(vicinity, player, messages)
        {vicinity, new_ap, new_hp}

      {:error, :not_edible, item_name} ->
        View.render(vicinity, player, [{"You can't eat #{item_name}.", :warning}])
        {vicinity, ap, hp}

      {:error, :invalid_index} ->
        View.render(vicinity, player, [{"Invalid item selection.", :warning}])
        {vicinity, ap, hp}

      {:error, reason} ->
        View.render(vicinity, player, [inability_message(reason)])
        {vicinity, ap, hp}
    end
  end

  def scribble(player, player_id, vicinity, ap, hp, text) do
    case Gateway.perform(player_id, vicinity.id, :scribble, text) do
      {:ok, new_ap} ->
        messages = [
          {"You scribble #{BlockDescription.scribble_surface(vicinity)}.", :success}
          | Constitution.threshold_messages(ap, new_ap, hp, hp)
        ]

        View.render(vicinity, player, messages)
        {vicinity, new_ap, hp}

      {:error, :empty_message} ->
        View.render(vicinity, player, [
          {"You scribble #{BlockDescription.scribble_surface(vicinity)}.", :success}
        ])

        {vicinity, ap, hp}

      {:error, :item_missing} ->
        View.render(vicinity, player, [{"You have no chalk.", :warning}])
        {vicinity, ap, hp}

      {:error, reason} ->
        View.render(vicinity, player, [inability_message(reason)])
        {vicinity, ap, hp}
    end
  end

  def unknown(player, vicinity, ap, hp) do
    View.render(vicinity, player, [
      {"Unknown command. Try: search, inventory, drop <n>, eat <n>, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
       :warning}
    ])

    {vicinity, ap, hp}
  end

  defp inability_message(reason), do: Map.fetch!(@inability_messages, reason)
end
