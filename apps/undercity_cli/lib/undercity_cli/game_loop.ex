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

  def run(player, player_id, vicinity) do
    render(vicinity, player, player_id)
    loop(player, player_id, vicinity)
  end

  defp loop(player, player_id, vicinity) do
    input = "> " |> IO.gets() |> String.trim() |> String.downcase()

    case parse(input) do
      :look ->
        render(vicinity, player, player_id)
        loop(player, player_id, vicinity)

      {:move, direction} ->
        vicinity = handle_move(player, player_id, vicinity, direction)
        loop(player, player_id, vicinity)

      :search ->
        handle_search(player, player_id, vicinity)
        loop(player, player_id, vicinity)

      :inventory ->
        handle_inventory(player, player_id, vicinity)
        loop(player, player_id, vicinity)

      {:scribble, text} ->
        handle_scribble(player, player_id, vicinity, text)
        loop(player, player_id, vicinity)

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

        loop(player, player_id, vicinity)
    end
  end

  defp handle_move(player, player_id, vicinity, direction) do
    case Gateway.move(player_id, direction, vicinity.id) do
      {:ok, new_vicinity} ->
        render(new_vicinity, player, player_id)
        new_vicinity

      {:error, :no_exit} ->
        render(vicinity, player, player_id, {"You can't go that way.", :warning})
        vicinity
    end
  end

  defp handle_search(player, player_id, vicinity) do
    message =
      case Gateway.search(player_id, vicinity.id) do
        {:found, item} -> {"You found #{item.name}!", :success}
        :nothing -> {"You find nothing.", :warning}
      end

    render(vicinity, player, player_id, message)
  end

  defp handle_inventory(player, player_id, vicinity) do
    items = Gateway.get_inventory(player_id)

    message =
      case items do
        [] -> {"Your inventory is empty.", :info}
        items -> {"Inventory: #{Enum.map_join(items, ", ", & &1.name)}", :info}
      end

    render(vicinity, player, player_id, message)
  end

  defp handle_scribble(player, player_id, vicinity, text) do
    message =
      case Gateway.scribble(player_id, vicinity.id, text) do
        :ok -> {"You scribble on the wall.", :success}
        {:error, :no_chalk} -> {"You have no chalk.", :warning}
        {:error, :invalid, reason} -> {reason, :warning}
      end

    render(vicinity, player, player_id, message)
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
