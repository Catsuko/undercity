defmodule UndercityCli.View.InventorySelector do
  @moduledoc """
  Interactive selector for choosing an item from inventory.

  NOTE: The `select/2` function uses blocking IO and is not compatible with the
  Ratatouille TEA runtime. It will be replaced with a model state transition in
  the selector rework (item 3 of the Owl→Ratatouille migration).
  """

  alias UndercityCli.MessageBuffer

  @type named :: %{name: String.t()}

  @spec select([named()], String.t()) :: {:ok, non_neg_integer()} | :cancel
  def select([], _label) do
    MessageBuffer.warn("Your inventory is empty.")
    :cancel
  end

  def select(items, _label) do
    options = build_options(items)
    read_loop(options)
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
