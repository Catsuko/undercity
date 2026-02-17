defmodule UndercityCli.GameLoop do
  @moduledoc """
  Interactive command loop for the CLI game.
  """

  alias UndercityCli.Commands
  alias UndercityCli.View

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

  def run(player, player_id, vicinity, ap, hp) do
    View.init()
    Commands.look(player, vicinity, ap, hp)
    loop(player, player_id, vicinity, ap, hp)
  end

  defp loop(player, player_id, vicinity, ap, hp) do
    input = View.read_input() |> String.trim() |> String.downcase()

    case Commands.dispatch(parse(input), player, player_id, vicinity, ap, hp) do
      :quit ->
        :ok

      {vicinity, ap, hp} ->
        loop(player, player_id, vicinity, ap, hp)
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
