defmodule UndercityCli.View.Screen do
  @moduledoc """
  Manages Owl.LiveScreen blocks for the CLI display.

  Registers persistent screen regions (blocks) that re-render in place.
  Block order: surroundings grid, block description, status messages.
  """

  alias UndercityCli.View.BlockDescription
  alias UndercityCli.View.Status
  alias UndercityCli.View.Surroundings

  def init do
    Application.ensure_all_started(:owl)

    if GenServer.whereis(Owl.LiveScreen), do: Owl.LiveScreen.stop()
    Owl.LiveScreen.start_link(name: Owl.LiveScreen)

    Owl.LiveScreen.add_block(:surroundings,
      state: nil,
      render: fn
        nil -> ""
        vicinity -> Surroundings.render(vicinity)
      end
    )

    Owl.LiveScreen.add_block(:description,
      state: nil,
      render: fn
        nil -> ""
        {vicinity, player} -> BlockDescription.render(vicinity, player)
      end
    )

    Owl.LiveScreen.add_block(:messages,
      state: [],
      render: fn
        [] -> ""
        messages -> Enum.intersperse(Enum.map(messages, fn {text, cat} -> Status.format_message(text, cat) end), "\n")
      end
    )
  end

  def update(vicinity, player, messages \\ []) do
    Owl.LiveScreen.update(:surroundings, vicinity)
    Owl.LiveScreen.update(:description, {vicinity, player})
    Owl.LiveScreen.update(:messages, messages)
  end

  def read_input do
    caller = self()

    Task.start(fn ->
      input = IO.gets("")
      IO.write(["\r", IO.ANSI.cursor_up(1), "\e[0K"])
      send(caller, {:input, input})
    end)

    receive do
      {:input, input} -> input
    end
  end
end
