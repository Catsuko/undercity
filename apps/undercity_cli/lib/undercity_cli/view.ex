defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  def describe_block(block_info, current_player) do
    [block_info.description, describe_people(block_info.people, current_player)]
    |> Enum.join("\n")
  end

  def describe_people(people, current_player) do
    others = Enum.reject(people, fn p -> p.name == current_player end)

    case others do
      [] -> "You are alone here."
      people -> "Present: #{Enum.map_join(people, ", ", & &1.name)}"
    end
  end
end
