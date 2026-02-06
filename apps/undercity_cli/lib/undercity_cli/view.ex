defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  def describe_block(block_info, current_player) do
    [
      ["\e[38;5;103m", block_info.name, IO.ANSI.reset()],
      ["\e[38;5;245m", block_info.description, IO.ANSI.reset()],
      "",
      describe_people(block_info.people, current_player)
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
end
