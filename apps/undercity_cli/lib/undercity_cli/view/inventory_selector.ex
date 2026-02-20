defmodule UndercityCli.View.InventorySelector do
  @moduledoc """
  Interactive selector for choosing an item from inventory.

  Renders a numbered list into the LiveScreen `:selector` block so that
  cancelling (or completing) clears the UI in-place. Numbers and the prompt
  use the same highlight color as the block name in `BlockDescription`.
  Returns the 0-based index of the selected item, or `:cancel`.
  """

  alias UndercityCli.MessageBuffer
  alias UndercityCli.View.Screen

  @highlight IO.ANSI.color(103)

  @spec select([UndercityCore.Item.t()], Owl.Data.t()) :: {:ok, non_neg_integer()} | :cancel
  def select([], _label) do
    MessageBuffer.warn("Your inventory is empty.")
    :cancel
  end

  def select(items, label) do
    options = build_options(items)
    Screen.update_selector(render_list(options, label))
    result = read_loop(options)
    Screen.update_selector(nil)
    result
  end

  @doc false
  def parse_choice(input, n) when is_binary(input) do
    case Integer.parse(String.trim(input)) do
      {i, ""} when i >= 1 and i <= n -> {:ok, i}
      _ -> :error
    end
  end

  def parse_choice(_, _), do: :error

  defp build_options(items), do: Enum.with_index(items) ++ [:cancel]

  defp render_option(:cancel), do: Owl.Data.tag("Cancel", :light_black)
  defp render_option({item, _index}), do: item.name

  defp render_list(options, label) do
    items =
      options
      |> Enum.with_index(1)
      |> Enum.map_intersperse("  ", fn {option, i} -> [number_tag(i), render_option(option)] end)

    [Owl.Data.tag(label, @highlight), "\n" | items]
  end

  defp number_tag(i) do
    Owl.Data.tag("#{i}. ", @highlight)
  end

  defp read_loop(options) do
    n = length(options)
    caller = self()

    Task.start(fn ->
      input = IO.gets("")
      IO.write(["\r", IO.ANSI.cursor_up(1), "\e[0K"])
      send(caller, {:selector_input, input})
    end)

    receive do
      {:selector_input, input} ->
        case parse_choice(input, n) do
          {:ok, i} ->
            case Enum.at(options, i - 1) do
              :cancel -> :cancel
              {_item, index} -> {:ok, index}
            end

          :error ->
            read_loop(options)
        end
    end
  end
end
