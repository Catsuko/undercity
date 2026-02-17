defmodule UndercityCli.View.Surroundings do
  @moduledoc """
  Renders the neighbourhood grid around the player's current block.
  """

  alias UndercityServer.Vicinity

  @cell_width 30
  @box_width 28

  @dim IO.ANSI.color(235)
  @grid_color IO.ANSI.color(245)
  @highlight IO.ANSI.color(103)
  @bg_fill IO.ANSI.color_background(236)

  def render(%Vicinity{neighbourhood: nil}), do: ""

  def render(%Vicinity{} = vicinity) do
    inside = if Vicinity.inside?(vicinity), do: centre_id(vicinity.neighbourhood)
    render_grid(vicinity.neighbourhood, inside)
  end

  defp render_grid(neighbourhood, inside) do
    line_color = if inside, do: @dim, else: @grid_color
    bar = String.duplicate("─", @cell_width)
    top = "#{line_color}┌#{bar}┬#{bar}┬#{bar}┐#{IO.ANSI.reset()}"
    mid = "#{line_color}├#{bar}┼#{bar}┼#{bar}┤#{IO.ANSI.reset()}"
    bot = "#{line_color}└#{bar}┴#{bar}┴#{bar}┘#{IO.ANSI.reset()}"

    rows =
      neighbourhood
      |> Enum.with_index()
      |> Enum.map(fn {row, r} ->
        render_row(row, r, inside, line_color)
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

  defp render_row(row, r, inside, line_color) do
    cells =
      row
      |> Enum.with_index()
      |> Enum.map(fn {block_id, c} ->
        name = if block_id, do: Vicinity.name_for(block_id)
        is_building = block_id != nil and Vicinity.building?(block_id)
        is_current = r == 1 and c == 1
        is_inside = inside != nil and block_id == inside
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

  defp centre_id(neighbourhood) do
    neighbourhood |> Enum.at(1) |> Enum.at(1)
  end
end
