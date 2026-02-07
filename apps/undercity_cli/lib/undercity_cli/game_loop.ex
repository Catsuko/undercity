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
    render(block_info, player)
    loop(server, player, block_info)
  end

  defp loop(server, player, block_info) do
    input = IO.gets("> ") |> String.trim() |> String.downcase()

    case parse(input) do
      :look ->
        render(block_info, player)
        loop(server, player, block_info)

      {:move, direction} ->
        case GameServer.move(server, player, direction, block_info.id) do
          {:ok, new_info} ->
            render(new_info, player)
            loop(server, player, new_info)

          {:error, :no_exit} ->
            render(block_info, player, "You can't go that way.")
            loop(server, player, block_info)
        end

      :quit ->
        :ok

      :unknown ->
        render(
          block_info,
          player,
          "Unknown command. Try: look, north/south/east/west (or n/s/e/w), quit"
        )

        loop(server, player, block_info)
    end
  end

  defp render(block_info, player, message \\ nil) do
    IO.write([IO.ANSI.clear(), IO.ANSI.home()])
    IO.puts(View.describe_block(block_info, player))
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
