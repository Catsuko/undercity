defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  @cell_width 20

  @descriptions %{
    street: "A narrow passage of broken cobblestones winding between crumbling walls.",
    square: "A wide, open space where the ground has been worn flat by countless feet.",
    fountain: "A stone basin sits at the centre of this space, dry and cracked.",
    graveyard: "Crooked headstones lean in black soil, their inscriptions worn smooth.",
    inn: "A sagging timber structure with a low doorway and walls darkened by smoke."
  }

  def describe_block(block_info, current_player) do
    grid = render_grid(block_info.neighbourhood)
    description = Map.fetch!(@descriptions, block_info.type)

    Enum.map_join(
      [
        grid,
        "",
        [
          "\e[38;5;245m",
          "You are at ",
          "\e[38;5;103m",
          block_info.name,
          "\e[38;5;245m",
          ". ",
          description,
          IO.ANSI.reset()
        ],
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
