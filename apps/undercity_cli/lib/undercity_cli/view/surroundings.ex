defmodule UndercityCli.View.Surroundings do
  @moduledoc """
  Renders the neighbourhood grid around the player's current block.
  """

  import Ratatouille.View

  alias UndercityServer.Vicinity

  @inner_width 33
  @box_inner @inner_width - 4
  @ncols 3
  @nlines 5
  @grid_width @ncols * (@inner_width + 1) + 1

  @grid_color Ratatouille.Constants.color(:white)
  @highlight Ratatouille.Constants.color(:cyan)

  def render(vicinity, window_width \\ 0)

  def render(%Vicinity{neighbourhood: nil}, _window_width), do: label(content: "")

  def render(%Vicinity{} = vicinity, window_width) do
    inside = if Vicinity.inside?(vicinity), do: centre_id(vicinity.neighbourhood)
    left_pad = max(0, div(window_width - 4 - @grid_width, 2))
    render_grid(vicinity.neighbourhood, inside, left_pad)
  end

  defp render_grid(neighbourhood, inside, left_pad) do
    nrows = length(neighbourhood)

    grid_data =
      neighbourhood
      |> Enum.with_index()
      |> Enum.map(fn {row, r} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {block_id, c} -> format_cell(block_id, r, c, inside) end)
      end)

    row_colors = Enum.map(grid_data, fn row -> Enum.map(row, fn {_, color} -> color end) end)

    middle_rows =
      grid_data
      |> Enum.with_index()
      |> Enum.flat_map(fn {row_data, r} ->
        content_rows = Enum.map(0..(@nlines - 1), &content_label(row_data, &1, left_pad))

        if r < nrows - 1 do
          colors_above = Enum.at(row_colors, r)
          colors_below = Enum.at(row_colors, r + 1)
          sep_colors = Enum.zip_with(colors_above, colors_below, &merge_border_color/2)
          content_rows ++ [border_label("├", "┼", "┤", sep_colors, left_pad)]
        else
          content_rows
        end
      end)

    [border_label("┌", "┬", "┐", Enum.at(row_colors, 0), left_pad)] ++
      middle_rows ++
      [border_label("└", "┴", "┘", List.last(row_colors), left_pad)]
  end

  defp merge_border_color(@highlight, _), do: @highlight
  defp merge_border_color(_, @highlight), do: @highlight
  defp merge_border_color(_, _), do: @grid_color

  defp border_label(left, mid, right, colors, left_pad) do
    horiz = String.duplicate("─", @inner_width)

    children =
      colors
      |> Enum.with_index()
      |> Enum.flat_map(fn {color, c} ->
        junction = if c == 0, do: left, else: mid
        prev_color = if c > 0, do: Enum.at(colors, c - 1)
        junction_color = if prev_color, do: merge_border_color(prev_color, color), else: color
        closing = if c == @ncols - 1, do: [text(content: right, color: color)], else: []

        [text(content: junction, color: junction_color), text(content: horiz, color: color)] ++
          closing
      end)

    pad_label(children, left_pad)
  end

  defp content_label(row_data, line_idx, left_pad) do
    border_colors = Enum.map(row_data, fn {_, border_color} -> border_color end)

    children =
      row_data
      |> Enum.with_index()
      |> Enum.flat_map(fn {{segments, border_color}, c} ->
        line_segs = Enum.at(segments, line_idx)

        prev_color = if c > 0, do: Enum.at(border_colors, c - 1)
        left_color = if prev_color, do: merge_border_color(prev_color, border_color), else: border_color
        closing = if c == @ncols - 1, do: [text(content: "│", color: border_color)], else: []

        seg_texts = Enum.map(line_segs, fn {str, color} -> text(content: str, color: color) end)
        [text(content: "│", color: left_color)] ++ seg_texts ++ closing
      end)

    pad_label(children, left_pad)
  end

  defp pad_label(children, n) when n <= 0, do: label(children)

  defp pad_label(children, n) do
    label([text(content: String.duplicate(" ", n), color: @grid_color)] ++ children)
  end

  defp format_cell(nil, _r, _c, _inside) do
    blank = [{String.duplicate(" ", @inner_width), @grid_color}]
    {List.duplicate(blank, @nlines), @grid_color}
  end

  defp format_cell(block_id, r, c, inside) do
    name = Vicinity.name_for(block_id)
    is_building = Vicinity.building?(block_id)
    is_center = r == 1 and c == 1
    is_inside = inside != nil

    border_color = if is_center, do: @highlight, else: @grid_color
    building_color = if is_center and is_inside, do: @highlight, else: @grid_color
    label_color = if is_center, do: @highlight, else: @grid_color

    segments =
      if is_building do
        eq = String.duplicate("═", @box_inner)
        inner_blank = String.duplicate(" ", @box_inner)

        [
          [{" ╔#{eq}╗ ", building_color}],
          [{" ║#{inner_blank}║ ", building_color}],
          [{" ║", building_color}, {pad_center(name, @box_inner), label_color}, {"║ ", building_color}],
          [{" ║#{inner_blank}║ ", building_color}],
          [{" ╚#{eq}╝ ", building_color}]
        ]
      else
        spaces = String.duplicate(" ", @inner_width)

        [
          [{spaces, label_color}],
          [{spaces, label_color}],
          [{pad_center(name, @inner_width), label_color}],
          [{spaces, label_color}],
          [{spaces, label_color}]
        ]
      end

    {segments, border_color}
  end

  defp centre_id(neighbourhood) do
    neighbourhood |> Enum.at(1) |> Enum.at(1)
  end

  defp pad_center(text, width) do
    text = if String.length(text) > width, do: String.slice(text, 0, width), else: text
    len = String.length(text)
    padding = width - len
    left = div(padding, 2)
    right = padding - left
    String.duplicate(" ", left) <> text <> String.duplicate(" ", right)
  end
end
