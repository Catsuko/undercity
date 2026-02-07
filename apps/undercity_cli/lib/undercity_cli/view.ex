defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  def describe_block(block_info, current_player) do
    [
      ["\e[38;5;103m", block_info.name, IO.ANSI.reset()],
      ["\e[38;5;245m", block_info.description, IO.ANSI.reset()],
      "",
      describe_people(block_info.people, current_player),
      describe_exits(block_info[:exits] || [])
    ]
    |> Enum.map_join("\n", &IO.iodata_to_binary/1)
  end

  def describe_people(people, current_player) do
    others = Enum.reject(people, fn p -> p.name == current_player end)

    case others do
      [] -> "You are alone here."
      people -> "Present: #{Enum.map_join(people, ", ", & &1.name)}"
    end
  end

  def describe_exits([]), do: "There are no exits."

  def describe_exits(exits) do
    directions = Enum.map_join(exits, ", ", fn {dir, _} -> to_string(dir) end)
    "Exits: #{directions}"
  end
end
