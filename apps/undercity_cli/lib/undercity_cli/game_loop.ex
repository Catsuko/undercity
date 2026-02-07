defmodule UndercityCli.GameLoop do
  @moduledoc """
  Interactive command loop for the CLI game.
  """

  alias UndercityCli.View
  alias UndercityServer.GameServer

  @directions %{
    "north" => :north,
    "south" => :south,
    "east" => :east,
    "west" => :west,
    "n" => :north,
    "s" => :south,
    "e" => :east,
    "w" => :west
  }

  def run(server, player, block_info) do
    loop(server, player, block_info)
  end

  defp loop(server, player, block_info) do
    input = IO.gets("> ") |> String.trim() |> String.downcase()

    case parse(input) do
      :look ->
        IO.puts(View.describe_block(block_info, player))
        loop(server, player, block_info)

      {:move, direction} ->
        case GameServer.move(server, player, direction, block_info.id) do
          {:ok, new_info} ->
            IO.puts(View.describe_block(new_info, player))
            loop(server, player, new_info)

          {:error, :no_exit} ->
            IO.puts("You can't go that way.")
            loop(server, player, block_info)
        end

      :quit ->
        IO.puts("You fade into the shadows...")

      :unknown ->
        IO.puts("Unknown command. Try: look, north/south/east/west (or n/s/e/w), quit")
        loop(server, player, block_info)
    end
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
