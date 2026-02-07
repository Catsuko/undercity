defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  @cell_width 20

  def describe_block(block_info, current_player) do
    grid = render_grid(block_info.neighbourhood)

    Enum.map_join(
      [
        grid,
        "",
        ["\e[38;5;103m", block_info.name, IO.ANSI.reset()],
        ["\e[38;5;245m", block_info.description, IO.ANSI.reset()],
        "",
        describe_people(block_info.people, current_player)
      ],
      "\n",
      &IO.iodata_to_binary/1
    )
  end

  def render_grid(neighbourhood) do
    bar = String.duplicate("─", @cell_width)
    top = "┌#{bar}┬#{bar}┬#{bar}┐"
    mid = "├#{bar}┼#{bar}┼#{bar}┤"
    bot = "└#{bar}┴#{bar}┴#{bar}┘"

    rows =
      neighbourhood
      |> Enum.with_index()
      |> Enum.map(fn {row, r} ->
        cells =
          row
          |> Enum.with_index()
          |> Enum.map(fn {name, c} -> render_cell(name, r, c) end)

        "│#{Enum.join(cells, "│")}│"
      end)

    Enum.join([top, Enum.at(rows, 0), mid, Enum.at(rows, 1), mid, Enum.at(rows, 2), bot], "\n")
  end

  defp render_cell(nil, _row, _col) do
    String.duplicate(" ", @cell_width)
  end

  defp render_cell(name, 1, 1) do
    text = pad_center(name, @cell_width)
    "\e[38;5;103m#{text}#{IO.ANSI.reset()}"
  end

  defp render_cell(name, _row, _col) do
    text = pad_center(name, @cell_width)
    "\e[38;5;245m#{text}#{IO.ANSI.reset()}"
  end

  defp pad_center(text, width) do
    text = if String.length(text) > width, do: String.slice(text, 0, width), else: text
    len = String.length(text)
    padding = width - len
    left = div(padding, 2)
    right = padding - left
    String.duplicate(" ", left) <> text <> String.duplicate(" ", right)
  end

  def describe_people(people, current_player) do
    others = Enum.reject(people, fn p -> p.name == current_player end)

    case others do
      [] -> "You are alone here."
      people -> "Present: #{Enum.map_join(people, ", ", & &1.name)}"
    end
  end
end
