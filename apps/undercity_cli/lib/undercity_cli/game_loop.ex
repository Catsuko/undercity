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

  def run(player, vicinity) do
    render(vicinity, player)
    loop(player, vicinity)
  end

  defp loop(player, vicinity) do
    input = "> " |> IO.gets() |> String.trim() |> String.downcase()

    case parse(input) do
      :look ->
        render(vicinity, player)
        loop(player, vicinity)

      {:move, direction} ->
        case Gateway.move(player, direction, vicinity.id) do
          {:ok, new_vicinity} ->
            render(new_vicinity, player)
            loop(player, new_vicinity)

          {:error, :no_exit} ->
            render(vicinity, player, "You can't go that way.")
            loop(player, vicinity)
        end

      :quit ->
        :ok

      :unknown ->
        render(
          vicinity,
          player,
          "Unknown command. Try: look, north/south/east/west (or n/s/e/w), enter, exit, quit"
        )

        loop(player, vicinity)
    end
  end

  defp render(vicinity, player, message \\ nil) do
    IO.write([IO.ANSI.clear(), IO.ANSI.home()])
    IO.puts(View.describe_block(vicinity, player))
    if message, do: IO.puts(message)
  end

  def parse("look"), do: :look
  def parse("l"), do: :look
  def parse("quit"), do: :quit
  def parse("q"), do: :quit

  def parse(input) do
    case Map.fetch(@directions, input) do
      {:ok, direction} -> {:move, direction}
      :error -> :unknown
    end
  end
end
