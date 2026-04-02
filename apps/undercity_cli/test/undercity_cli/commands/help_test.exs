defmodule UndercityCli.Commands.HelpTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Help

  test "displays each usage hint as a separate info message and returns model unchanged" do
    Commands.usage_hints()
    |> String.split("\n")
    |> Enum.each(fn hint ->
      expect(MessageBuffer, :info, fn msg ->
        assert msg == hint
        :ok
      end)
    end)

    assert Help.dispatch("help", @state) == @state
  end
end
