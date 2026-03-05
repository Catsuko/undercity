defmodule UndercityCli.Commands.HelpTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Help

  test "displays usage hints and returns model unchanged" do
    expect(MessageBuffer, :info, fn msg ->
      assert msg == Commands.usage_hints()
      :ok
    end)

    assert Help.dispatch("help", @state) == @state
  end
end
