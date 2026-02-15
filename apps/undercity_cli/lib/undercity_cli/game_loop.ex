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

    case parse(input) do
      :look ->
        render(vicinity, player, player_id)
        loop(player, player_id, vicinity, ap)

      {:move, direction} ->
        {vicinity, ap} = handle_move(player, player_id, vicinity, ap, direction)
        loop(player, player_id, vicinity, ap)

      :search ->
        ap = handle_search(player, player_id, vicinity, ap)
        loop(player, player_id, vicinity, ap)

      :inventory ->
        handle_inventory(player, player_id, vicinity)
        loop(player, player_id, vicinity, ap)

      {:scribble, text} ->
        ap = handle_scribble(player, player_id, vicinity, ap, text)
        loop(player, player_id, vicinity, ap)

      :quit ->
        :ok

      :unknown ->
        render(
          vicinity,
          player,
          player_id,
          {"Unknown command. Try: look, search, inventory, scribble <text>, north/south/east/west (or n/s/e/w), enter, exit, quit",
           :warning}
        )

        loop(player, player_id, vicinity, ap)
    end
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

      {:ok, :nothing, new_ap} ->
        render(vicinity, player, player_id, {"You find nothing.", :warning})
        show_threshold(ap, new_ap)
        new_ap

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
  def parse("scribble " <> text), do: {:scribble, text}

  def parse(input) do
    case Map.fetch(@directions, input) do
      {:ok, direction} -> {:move, direction}
      :error -> :unknown
    end
  end
end
