defmodule UndercityCli.View do
  @moduledoc """
  Formats server data for CLI display.
  """

  alias UndercityServer.Vicinity

  @cell_width 30
  @box_width 28

  @descriptions %{
    street: "A narrow passage of broken cobblestones winding between crumbling walls.",
    square: "A wide, open space where the ground has been worn flat by countless feet.",
    fountain: "A stone basin sits at the centre of this space, dry and cracked.",
    graveyard: "Crooked headstones lean in black soil, their inscriptions worn smooth.",
    space: "A patch of open ground before a squat building, its timbers warped and dark.",
    space_inn: "A crooked timber frame leans over the street, its shuttered windows half-rotted from the damp.",
    inn: "Low beams sag overhead in a room thick with the smell of damp wood and old smoke."
  }

  @dim "\e[38;5;235m"
  @grid_color "\e[38;5;245m"
  @highlight "\e[38;5;103m"
  @bg_fill "\e[48;5;236m"

  def describe_block(%Vicinity{} = vicinity, current_player) do
    description = Map.fetch!(@descriptions, description_key(vicinity))
    prefix = block_prefix(vicinity.type)
    inside = Vicinity.inside?(vicinity)
    name = Vicinity.name(vicinity)

    sections =
      case vicinity.neighbourhood do
        nil ->
          []

        neighbourhood ->
          parent = if inside, do: centre_id(neighbourhood)
          [render_grid(neighbourhood, parent), ""]
      end

    sections =
      sections ++
        [
          [
            "\e[38;5;245m",
            "You are #{prefix} ",
            "\e[38;5;103m",
            name,
            "\e[38;5;245m",
            ". ",
            description,
            IO.ANSI.reset()
          ]
        ]

    sections =
      sections ++
        case vicinity.scribble do
          nil ->
            []

          text ->
            surface = scribble_surface(vicinity)

            [
              [
                "\e[38;5;245mSomeone has scribbled \e[3m",
                text,
                "\e[23m #{surface}.",
                IO.ANSI.reset()
              ]
            ]
        end

    sections = sections ++ ["", describe_people(vicinity.people, current_player)]

    Enum.map_join(sections, "\n", &IO.iodata_to_binary/1)
  end

  defp description_key(%Vicinity{type: :space, building_type: bt}) when bt != nil, do: :"space_#{bt}"

  defp description_key(%Vicinity{type: type}), do: type

  defp block_prefix(:space), do: "outside"
  defp block_prefix(:inn), do: "inside"
  defp block_prefix(_type), do: "at"

  defp centre_id(neighbourhood) do
    neighbourhood |> Enum.at(1) |> Enum.at(1)
  end

  def render_grid(neighbourhood, inside \\ nil) do
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

  def scribble_surface(%Vicinity{type: :graveyard}), do: "on a tombstone"
  def scribble_surface(%Vicinity{type: :inn}), do: "on the wall"
  def scribble_surface(%Vicinity{type: :space, building_type: bt}) when bt != nil, do: "on the wall"
  def scribble_surface(%Vicinity{}), do: "on the ground"

  def describe_people(people, current_player) do
    others = Enum.reject(people, fn p -> p.name == current_player end)

    case others do
      [] -> "You are alone here."
      people -> "Present: #{Enum.map_join(people, ", ", & &1.name)}"
    end
  end

  def format_message(message, category \\ :info)
  def format_message(message, :success), do: "\e[38;5;108m▸ #{message}#{IO.ANSI.reset()}"
  def format_message(message, :info), do: "\e[38;5;67m▸ #{message}#{IO.ANSI.reset()}"
  def format_message(message, :warning), do: "\e[38;5;131m▸ #{message}#{IO.ANSI.reset()}"

  @doc """
  Returns the awareness tier for a given AP value.
  """
  def awareness_tier(0), do: :spent
  def awareness_tier(ap) when ap >= 40, do: :rested
  def awareness_tier(ap) when ap >= 16, do: :weary
  def awareness_tier(_ap), do: :exhausted

  @doc """
  Returns a status message for the current AP tier.
  """
  def status_message(ap), do: tier_message(awareness_tier(ap))

  @doc """
  Returns a threshold crossing message if AP dropped into a new tier, or nil.
  """
  def threshold_message(old_ap, new_ap) do
    old_tier = awareness_tier(old_ap)
    new_tier = awareness_tier(new_ap)

    if old_tier != new_tier do
      tier_message(new_tier)
    end
  end

  defp tier_message(:rested), do: {"You feel rested.", :success}
  defp tier_message(:weary), do: {"You feel weary.", :warning}
  defp tier_message(:exhausted), do: {"You can barely keep your eyes open.", :warning}
  defp tier_message(:spent), do: {"You are completely exhausted.", :warning}
end
