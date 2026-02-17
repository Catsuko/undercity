defmodule UndercityCli.GameLoop do
  @moduledoc """
  Interactive command loop for the CLI game.
  """

  alias UndercityCli.View
  alias UndercityServer.Gateway

  @directions %{
    "north" => :north,
    "south" => :south,
    "east" => :east,
    "west" => :west,
    "n" => :north,
    "s" => :south,
    "e" => :east,
    "w" => :west,
    "enter" => :enter,
    "exit" => :exit
  }

  @inability_messages %{
    exhausted: {"You are too exhausted to act.", :warning},
    collapsed: {"Your body has given out.", :warning}
  }

  def run(player, player_id, vicinity, ap, hp) do
    View.render(vicinity, player)
    View.render_constitution(ap, hp)
    loop(player, player_id, vicinity, ap, hp)
  end

  defp loop(player, player_id, vicinity, ap, hp) do
    input = "> " |> IO.gets() |> String.trim() |> String.downcase()

    case dispatch(parse(input), player, player_id, vicinity, ap, hp) do
      :quit -> :ok
      {vicinity, ap, hp} -> loop(player, player_id, vicinity, ap, hp)
    end
  end

  defp dispatch(:look, player, _player_id, vicinity, ap, hp) do
    View.render(vicinity, player)
    {vicinity, ap, hp}
  end

  defp dispatch({:move, direction}, player, player_id, vicinity, ap, hp) do
    handle_move(player, player_id, vicinity, ap, hp, direction)
  end

  defp dispatch(:search, player, player_id, vicinity, ap, hp) do
    {vicinity, handle_search(player, player_id, vicinity, ap, hp), hp}
  end

  defp dispatch(:inventory, player, player_id, vicinity, ap, hp) do
    handle_inventory(player, player_id, vicinity)
    {vicinity, ap, hp}
  end

  defp dispatch({:drop, index}, player, player_id, vicinity, ap, hp) do
    {vicinity, handle_drop(player, player_id, vicinity, ap, hp, index), hp}
  end

  defp dispatch({:eat, index}, player, player_id, vicinity, ap, hp) do
    {new_ap, new_hp} = handle_eat(player, player_id, vicinity, ap, hp, index)
    {vicinity, new_ap, new_hp}
  end

  defp dispatch({:scribble, text}, player, player_id, vicinity, ap, hp) do
    {vicinity, handle_scribble(player, player_id, vicinity, ap, hp, text), hp}
  end

  defp dispatch(:quit, _player, _player_id, _vicinity, _ap, _hp), do: :quit

  defp dispatch(:unknown, player, _player_id, vicinity, ap, hp) do
    View.render(vicinity, player)

    View.render_message(
      {"Unknown command. Try: look, search, inventory, drop <n>, eat <n>, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
       :warning}
    )

    {vicinity, ap, hp}
  end

  defp handle_move(player, player_id, vicinity, ap, hp, direction) do
    case Gateway.perform(player_id, vicinity.id, :move, direction) do
      {:ok, {:ok, new_vicinity}, new_ap} ->
        View.render(new_vicinity, player)
        View.render_constitution(new_ap, hp, ap)
        {new_vicinity, new_ap, hp}

      {:ok, {:error, :no_exit}, new_ap} ->
        View.render(vicinity, player)
        View.render_message({"You can't go that way.", :warning})
        View.render_constitution(new_ap, hp, ap)
        {vicinity, new_ap, hp}

      {:error, reason} ->
        View.render(vicinity, player)
        View.render_message(inability_message(reason))
        {vicinity, ap, hp}
    end
  end

  defp handle_search(player, player_id, vicinity, ap, hp) do
    case Gateway.perform(player_id, vicinity.id, :search, nil) do
      {:ok, {:found, item}, new_ap} ->
        View.render(vicinity, player)
        View.render_message({"You found #{item.name}!", :success})
        View.render_constitution(new_ap, hp, ap)
        new_ap

      {:ok, {:found_but_full, item}, new_ap} ->
        View.render(vicinity, player)
        View.render_message({"You found #{item.name}, but your inventory is full.", :warning})
        View.render_constitution(new_ap, hp, ap)
        new_ap

      {:ok, :nothing, new_ap} ->
        View.render(vicinity, player)
        View.render_message({"You find nothing.", :warning})
        View.render_constitution(new_ap, hp, ap)
        new_ap

      {:error, reason} ->
        View.render(vicinity, player)
        View.render_message(inability_message(reason))
        ap
    end
  end

  defp handle_drop(player, player_id, vicinity, ap, hp, index) do
    case Gateway.drop_item(player_id, index) do
      {:ok, item_name, new_ap} ->
        View.render(vicinity, player)
        View.render_message({"You dropped #{item_name}.", :info})
        View.render_constitution(new_ap, hp, ap)
        new_ap

      {:error, :invalid_index} ->
        View.render(vicinity, player)
        View.render_message({"Invalid item selection.", :warning})
        ap

      {:error, reason} ->
        View.render(vicinity, player)
        View.render_message(inability_message(reason))
        ap
    end
  end

  defp handle_eat(player, player_id, vicinity, ap, hp, index) do
    case Gateway.perform(player_id, vicinity.id, :eat, index) do
      {:ok, item, _effect, new_ap, new_hp} ->
        View.render(vicinity, player)
        View.render_message({"Ate a #{item.name}.", :success})
        View.render_constitution(new_ap, new_hp, ap, hp)
        {new_ap, new_hp}

      {:error, :not_edible, item_name} ->
        View.render(vicinity, player)
        View.render_message({"You can't eat #{item_name}.", :warning})
        {ap, hp}

      {:error, :invalid_index} ->
        View.render(vicinity, player)
        View.render_message({"Invalid item selection.", :warning})
        {ap, hp}

      {:error, reason} ->
        View.render(vicinity, player)
        View.render_message(inability_message(reason))
        {ap, hp}
    end
  end

  defp handle_inventory(player, player_id, vicinity) do
    items = Gateway.check_inventory(player_id)

    View.render(vicinity, player)

    case items do
      [] -> View.render_message({"Your inventory is empty.", :info})
      items -> View.render_message({"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info})
    end
  end

  defp handle_scribble(player, player_id, vicinity, ap, hp, text) do
    case Gateway.perform(player_id, vicinity.id, :scribble, text) do
      {:ok, new_ap} ->
        View.render(vicinity, player)
        View.render_message({"You scribble #{View.scribble_surface(vicinity)}.", :success})
        View.render_constitution(new_ap, hp, ap)
        new_ap

      {:error, :empty_message} ->
        View.render(vicinity, player)
        View.render_message({"You scribble #{View.scribble_surface(vicinity)}.", :success})
        ap

      {:error, :item_missing} ->
        View.render(vicinity, player)
        View.render_message({"You have no chalk.", :warning})
        ap

      {:error, reason} ->
        View.render(vicinity, player)
        View.render_message(inability_message(reason))
        ap
    end
  end

  defp inability_message(reason), do: Map.fetch!(@inability_messages, reason)

  def parse("look"), do: :look
  def parse("l"), do: :look
  def parse("search"), do: :search
  def parse("inventory"), do: :inventory
  def parse("i"), do: :inventory
  def parse("quit"), do: :quit
  def parse("q"), do: :quit

  def parse("drop " <> index_str) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 -> {:drop, n - 1}
      _ -> :unknown
    end
  end

  def parse("eat " <> index_str) do
    case Integer.parse(index_str) do
      {n, ""} when n >= 1 -> {:eat, n - 1}
      _ -> :unknown
    end
  end

  def parse("scribble " <> text), do: {:scribble, text}

  def parse(input) do
    case Map.fetch(@directions, input) do
      {:ok, direction} -> {:move, direction}
      :error -> :unknown
    end
  end
end
