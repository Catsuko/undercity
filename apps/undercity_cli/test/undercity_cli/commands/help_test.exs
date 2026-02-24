defmodule UndercityCli.Commands.HelpTest do
  use UndercityCli.CommandCase

  alias UndercityCli.Commands
  alias UndercityCli.Commands.Help

  test "displays usage hints and returns continue with unchanged state" do
    expect(MessageBuffer, :info, fn msg ->
      assert msg == Commands.usage_hints()
      :ok
    end)

    assert {:continue, new_state} = Help.dispatch("help", @state, Gateway, MessageBuffer)
    assert new_state == @state
  end
end
