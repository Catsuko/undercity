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

  def render_to_string(%Vicinity{neighbourhood: nil}), do: ""

  def render_to_string(%Vicinity{} = vicinity) do
    inside = if Vicinity.inside?(vicinity), do: centre_id(vicinity.neighbourhood)
    render_table(vicinity.neighbourhood, inside)
  end

  defp render_table(neighbourhood, inside) do
    [header_row | body_rows] = neighbourhood

    header_cells =
      header_row
      |> Enum.with_index()
      |> Map.new(fn {block_id, c} -> {c, format_cell(block_id, 0, c, inside)} end)

    rows =
      body_rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, r} ->
        row
        |> Enum.with_index()
        |> Map.new(fn {block_id, c} -> {c, format_cell(block_id, r, c, inside)} end)
      end)

    rows
    |> Owl.Table.new(
      render_cell: [
        header: &Map.fetch!(header_cells, &1),
        body: & &1
      ],
      border_style: :solid,
      divide_body_rows: true
    )
    |> to_owl_string()
  end

  defp format_cell(nil, _r, _c, _inside) do
    blank = String.duplicate(" ", @cell_width)
    Enum.join([blank, blank, blank], "\n")
  end

  defp format_cell(block_id, r, c, inside) do
    name = Vicinity.name_for(block_id)
    is_building = Vicinity.building?(block_id)
    is_current = r == 1 and c == 1
    is_inside_this = inside != nil and block_id == inside
    dimmed = inside != nil

    cond do
      is_building and is_inside_this -> format_building_inside(name)
      is_building -> format_building(name, is_current, dimmed)
      true -> format_plain(name, is_current, dimmed)
    end
  end

  defp format_plain(name, is_current, dimmed) do
    text = pad_center(name, @cell_width)
    blank = String.duplicate(" ", @cell_width)

    color =
      cond do
        dimmed -> @dim
        is_current -> @highlight
        true -> @grid_color
      end

    [blank, "\n", Owl.Data.tag(text, color), "\n", blank]
  end

  defp format_building_inside(name) do
    inner_width = @box_width - 2
    text = pad_center(name, inner_width)
    pad = div(@cell_width - @box_width, 2)
    side_pad = String.duplicate(" ", pad)

    top = [
      Owl.Data.tag(side_pad, @dim),
      Owl.Data.tag("╔#{String.duplicate("═", inner_width)}╗", @highlight),
      Owl.Data.tag(side_pad, @dim)
    ]

    mid = [
      Owl.Data.tag(side_pad, @dim),
      Owl.Data.tag("║#{text}║", @highlight),
      Owl.Data.tag(side_pad, @dim)
    ]

    bot = [
      Owl.Data.tag(side_pad, @dim),
      Owl.Data.tag("╚#{String.duplicate("═", inner_width)}╝", @highlight),
      Owl.Data.tag(side_pad, @dim)
    ]

    [top, "\n", mid, "\n", bot]
  end

  defp format_building(name, is_current, dimmed) do
    inner_width = @box_width - 2
    text = pad_center(name, inner_width)
    pad = div(@cell_width - @box_width, 2)
    side_pad = String.duplicate(" ", pad)

    box_color = if dimmed, do: @dim, else: @grid_color
    text_color = if dimmed, do: @dim, else: if(is_current, do: @highlight, else: @grid_color)

    top =
      Owl.Data.tag(
        "#{side_pad}╔#{String.duplicate("═", inner_width)}╗#{side_pad}",
        box_color
      )

    mid = [
      Owl.Data.tag("#{side_pad}║", box_color),
      Owl.Data.tag(text, text_color),
      Owl.Data.tag("║#{side_pad}", box_color)
    ]

    bot =
      Owl.Data.tag(
        "#{side_pad}╚#{String.duplicate("═", inner_width)}╝#{side_pad}",
        box_color
      )

    [top, "\n", mid, "\n", bot]
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

  defp to_owl_string(data), do: data |> Owl.Data.to_chardata() |> IO.iodata_to_binary()
end
