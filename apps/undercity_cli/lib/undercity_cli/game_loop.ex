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

  @exhausted_message {"You are too exhausted to act.", :warning}

  def run(player, player_id, vicinity, ap) do
    render(vicinity, player, player_id)
    show_status(ap)
    loop(player, player_id, vicinity, ap)
  end

  defp loop(player, player_id, vicinity, ap) do
    input = "> " |> IO.gets() |> String.trim() |> String.downcase()

    case dispatch(parse(input), player, player_id, vicinity, ap) do
      :quit -> :ok
      {vicinity, ap} -> loop(player, player_id, vicinity, ap)
    end
  end

  defp dispatch(:look, player, player_id, vicinity, ap) do
    render(vicinity, player, player_id)
    {vicinity, ap}
  end

  defp dispatch({:move, direction}, player, player_id, vicinity, ap) do
    handle_move(player, player_id, vicinity, ap, direction)
  end

  defp dispatch(:search, player, player_id, vicinity, ap) do
    {vicinity, handle_search(player, player_id, vicinity, ap)}
  end

  defp dispatch(:inventory, player, player_id, vicinity, ap) do
    handle_inventory(player, player_id, vicinity)
    {vicinity, ap}
  end

  defp dispatch({:drop, index}, player, player_id, vicinity, ap) do
    {vicinity, handle_drop(player, player_id, vicinity, ap, index)}
  end

  defp dispatch({:eat, index}, player, player_id, vicinity, ap) do
    {vicinity, handle_eat(player, player_id, vicinity, ap, index)}
  end

  defp dispatch({:scribble, text}, player, player_id, vicinity, ap) do
    {vicinity, handle_scribble(player, player_id, vicinity, ap, text)}
  end

  defp dispatch(:quit, _player, _player_id, _vicinity, _ap), do: :quit

  defp dispatch(:unknown, player, player_id, vicinity, ap) do
    render(
      vicinity,
      player,
      player_id,
      {"Unknown command. Try: look, search, inventory, drop <n>, eat <n>, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
       :warning}
    )

    {vicinity, ap}
  end

  defp handle_move(player, player_id, vicinity, ap, direction) do
    case Gateway.perform(player_id, vicinity.id, :move, direction) do
      {:ok, {:ok, new_vicinity}, new_ap} ->
        render(new_vicinity, player, player_id, View.threshold_message(ap, new_ap))
        {new_vicinity, new_ap}

      {:ok, {:error, :no_exit}, new_ap} ->
        render(vicinity, player, player_id, {"You can't go that way.", :warning})
        show_threshold(ap, new_ap)
        {vicinity, new_ap}

      {:error, :exhausted} ->
        render(vicinity, player, player_id, @exhausted_message)
        {vicinity, ap}
    end
  end

  defp handle_search(player, player_id, vicinity, ap) do
    case Gateway.perform(player_id, vicinity.id, :search, nil) do
      {:ok, {:found, item}, new_ap} ->
        render(vicinity, player, player_id, {"You found #{item.name}!", :success})
        show_threshold(ap, new_ap)
        new_ap

      {:ok, {:found_but_full, item}, new_ap} ->
        render(vicinity, player, player_id, {"You found #{item.name}, but your inventory is full.", :warning})
        show_threshold(ap, new_ap)
        new_ap

      {:ok, :nothing, new_ap} ->
        render(vicinity, player, player_id, {"You find nothing.", :warning})
        show_threshold(ap, new_ap)
        new_ap

      {:error, :exhausted} ->
        render(vicinity, player, player_id, @exhausted_message)
        ap
    end
  end

  defp handle_drop(player, player_id, vicinity, ap, index) do
    case Gateway.drop_item(player_id, index) do
      {:ok, item_name, new_ap} ->
        render(vicinity, player, player_id, {"You dropped #{item_name}.", :info})
        show_threshold(ap, new_ap)
        new_ap

      {:error, :invalid_index} ->
        render(vicinity, player, player_id, {"Invalid item selection.", :warning})
        ap

      {:error, :exhausted} ->
        render(vicinity, player, player_id, @exhausted_message)
        ap
    end
  end

  defp handle_eat(player, player_id, vicinity, ap, index) do
    case Gateway.perform(player_id, vicinity.id, :eat, index) do
      {:ok, item, _effect, new_ap} ->
        render(vicinity, player, player_id, {"Ate a #{item.name}.", :success})
        show_threshold(ap, new_ap)
        new_ap

      {:error, :not_edible, item_name} ->
        render(vicinity, player, player_id, {"You can't eat #{item_name}.", :warning})
        ap

      {:error, :invalid_index} ->
        render(vicinity, player, player_id, {"Invalid item selection.", :warning})
        ap

      {:error, :exhausted} ->
        render(vicinity, player, player_id, @exhausted_message)
        ap
    end
  end

  defp handle_inventory(player, player_id, vicinity) do
    items = Gateway.check_inventory(player_id)

    message =
      case items do
        [] -> {"Your inventory is empty.", :info}
        items -> {"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info}
      end

    render(vicinity, player, player_id, message)
  end

  defp handle_scribble(player, player_id, vicinity, ap, text) do
    case Gateway.perform(player_id, vicinity.id, :scribble, text) do
      {:ok, new_ap} ->
        render(vicinity, player, player_id, {"You scribble #{View.scribble_surface(vicinity)}.", :success})
        show_threshold(ap, new_ap)
        new_ap

      {:error, :empty_message} ->
        render(vicinity, player, player_id, {"You scribble #{View.scribble_surface(vicinity)}.", :success})
        ap

      {:error, :item_missing} ->
        render(vicinity, player, player_id, {"You have no chalk.", :warning})
        ap

      {:error, :exhausted} ->
        render(vicinity, player, player_id, @exhausted_message)
        ap
    end
  end

  defp show_status(ap) do
    {text, category} = View.status_message(ap)
    IO.puts("\n" <> View.format_message(text, category))
  end

  defp show_threshold(old_ap, new_ap) do
    case View.threshold_message(old_ap, new_ap) do
      {text, category} -> IO.puts(View.format_message(text, category))
      nil -> :ok
    end
  end

  defp render(vicinity, player, _player_id, message \\ nil) do
    IO.write([IO.ANSI.clear(), IO.ANSI.home()])
    IO.puts(View.describe_block(vicinity, player))

    case message do
      {text, category} -> IO.puts("\n" <> View.format_message(text, category))
      nil -> :ok
    end
  end

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
