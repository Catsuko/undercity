defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  @cell_width 20
  @box_width 18

  @descriptions %{
    street: "A narrow passage of broken cobblestones winding between crumbling walls.",
    square: "A wide, open space where the ground has been worn flat by countless feet.",
    fountain: "A stone basin sits at the centre of this space, dry and cracked.",
    graveyard: "Crooked headstones lean in black soil, their inscriptions worn smooth.",
    space: "A patch of open ground before a squat building, its timbers warped and dark.",
    inn: "A sagging timber structure with a low doorway and walls darkened by smoke."
  }

  @dim "\e[38;5;235m"
  @grid_color "\e[38;5;245m"
  @highlight "\e[38;5;103m"
  @bg_fill "\e[48;5;236m"

  def describe_block(block_info, current_player) do
    description = Map.fetch!(@descriptions, block_info.type)
    prefix = block_prefix(block_info.type)
    buildings = Map.get(block_info, :buildings, MapSet.new())
    inside = Map.get(block_info, :inside)

    sections =
      case block_info.neighbourhood do
        nil -> []
        neighbourhood -> [render_grid(neighbourhood, buildings, inside), ""]
      end

    sections =
      sections ++
        [
          [
            "\e[38;5;245m",
            "You are #{prefix} ",
            "\e[38;5;103m",
            block_info.name,
            "\e[38;5;245m",
            ". ",
            description,
            IO.ANSI.reset()
          ],
          "",
          describe_people(block_info.people, current_player)
        ]

    Enum.map_join(sections, "\n", &IO.iodata_to_binary/1)
  end

  defp block_prefix(:space), do: "outside"
  defp block_prefix(:inn), do: "inside"
  defp block_prefix(_type), do: "at"

  def render_grid(neighbourhood, buildings \\ MapSet.new(), inside \\ nil) do
    line_color = if inside, do: @dim, else: @grid_color
    bar = String.duplicate("─", @cell_width)
    top = "#{line_color}┌#{bar}┬#{bar}┬#{bar}┐#{IO.ANSI.reset()}"
    mid = "#{line_color}├#{bar}┼#{bar}┼#{bar}┤#{IO.ANSI.reset()}"
    bot = "#{line_color}└#{bar}┴#{bar}┴#{bar}┘#{IO.ANSI.reset()}"

    rows =
      neighbourhood
      |> Enum.with_index()
      |> Enum.map(fn {row, r} ->
        render_row(row, r, buildings, inside, line_color)
      end)

    [
      top,
      Enum.at(rows, 0),
      mid,
      Enum.at(rows, 1),
      mid,
      Enum.at(rows, 2),
      bot
    ]
    |> List.flatten()
    |> Enum.join("\n")
  end

  defp render_row(row, r, buildings, inside, line_color) do
    cells =
      row
      |> Enum.with_index()
      |> Enum.map(fn {name, c} ->
        is_building = name != nil and MapSet.member?(buildings, name)
        is_current = r == 1 and c == 1
        is_inside = inside != nil and name == inside
        render_cell_lines(name, is_building, is_current, is_inside, inside != nil)
      end)

    pipe = "#{line_color}│#{IO.ANSI.reset()}"

    for line <- 0..2 do
      cell_line =
        Enum.map_join(cells, pipe, fn lines -> Enum.at(lines, line) end)

      "#{pipe}#{cell_line}#{pipe}"
    end
  end

  defp render_cell_lines(nil, _building, _current, _inside_this, dimmed) do
    color = if dimmed, do: @dim, else: @grid_color
    blank = "#{color}#{String.duplicate(" ", @cell_width)}#{IO.ANSI.reset()}"
    [blank, blank, blank]
  end

  defp render_cell_lines(name, true, _is_current, true, _dimmed) do
    # Inside this building: highlighted text with background fill
    inner_width = @box_width - 2
    text = pad_center(name, inner_width)
    pad = div(@cell_width - @box_width, 2)
    side_pad = String.duplicate(" ", pad)

    top_line =
      "#{@dim}#{side_pad}#{@highlight}╔#{String.duplicate("═", inner_width)}╗#{@dim}#{side_pad}#{IO.ANSI.reset()}"

    mid_line =
      "#{@dim}#{side_pad}#{@highlight}║#{@bg_fill}#{text}#{IO.ANSI.reset()}#{@highlight}║#{@dim}#{side_pad}#{IO.ANSI.reset()}"

    bot_line =
      "#{@dim}#{side_pad}#{@highlight}╚#{String.duplicate("═", inner_width)}╝#{@dim}#{side_pad}#{IO.ANSI.reset()}"

    [top_line, mid_line, bot_line]
  end

  defp render_cell_lines(name, true, is_current, false, dimmed) do
    # Building cell (not inside): box with appropriate colour
    inner_width = @box_width - 2
    text = pad_center(name, inner_width)
    pad = div(@cell_width - @box_width, 2)
    side_pad = String.duplicate(" ", pad)

    box_color = if dimmed, do: @dim, else: @grid_color
    text_color = if dimmed, do: @dim, else: if(is_current, do: @highlight, else: @grid_color)

    top_line = "#{box_color}#{side_pad}╔#{String.duplicate("═", inner_width)}╗#{side_pad}#{IO.ANSI.reset()}"
    mid_line = "#{box_color}#{side_pad}║#{text_color}#{text}#{box_color}║#{side_pad}#{IO.ANSI.reset()}"
    bot_line = "#{box_color}#{side_pad}╚#{String.duplicate("═", inner_width)}╝#{side_pad}#{IO.ANSI.reset()}"

    [top_line, mid_line, bot_line]
  end

  defp render_cell_lines(name, false, is_current, _inside_this, dimmed) do
    # Normal cell (no building)
    text = pad_center(name, @cell_width)
    blank = String.duplicate(" ", @cell_width)

    color =
      cond do
        dimmed -> @dim
        is_current -> @highlight
        true -> @grid_color
      end

    [blank, "#{color}#{text}#{IO.ANSI.reset()}", blank]
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
