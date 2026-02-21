defmodule UndercityCli.MessageBufferTest do
  use ExUnit.Case, async: false

  alias UndercityCli.MessageBuffer

  setup do
    start_supervised!(MessageBuffer)
    :ok
  end

  describe "push/2" do
    test "accumulates a single message" do
      MessageBuffer.push("Hello", :info)
      assert MessageBuffer.flush() == [{"Hello", :info}]
    end

    test "accumulates multiple messages in order" do
      MessageBuffer.push("First", :info)
      MessageBuffer.push("Second", :warning)
      assert MessageBuffer.flush() == [{"First", :info}, {"Second", :warning}]
    end

    test "accepts all valid categories" do
      MessageBuffer.push("Success", :success)
      MessageBuffer.push("Info", :info)
      MessageBuffer.push("Warning", :warning)
      assert MessageBuffer.flush() == [{"Success", :success}, {"Info", :info}, {"Warning", :warning}]
    end
  end

  describe "push/1" do
    test "accumulates a list of messages" do
      MessageBuffer.push([{"Hello", :info}, {"World", :warning}])
      assert MessageBuffer.flush() == [{"Hello", :info}, {"World", :warning}]
    end

    test "appends list messages after previously pushed messages" do
      MessageBuffer.push("First", :info)
      MessageBuffer.push([{"Second", :warning}, {"Third", :success}])
      assert MessageBuffer.flush() == [{"First", :info}, {"Second", :warning}, {"Third", :success}]
    end

    test "ignores empty list" do
      MessageBuffer.push([])
      assert MessageBuffer.flush() == []
    end
  end

  describe "info/1" do
    test "pushes an info message" do
      MessageBuffer.info("Hello")
      assert MessageBuffer.flush() == [{"Hello", :info}]
    end
  end

  describe "success/1" do
    test "pushes a success message" do
      MessageBuffer.success("Well done")
      assert MessageBuffer.flush() == [{"Well done", :success}]
    end
  end

  describe "warn/1" do
    test "pushes a warning message" do
      MessageBuffer.warn("Watch out")
      assert MessageBuffer.flush() == [{"Watch out", :warning}]
    end
  end

  describe "flush/0" do
    test "returns empty list when buffer is empty" do
      assert MessageBuffer.flush() == []
    end

    test "clears the buffer after flushing" do
      MessageBuffer.push("Hello", :info)
      MessageBuffer.flush()
      assert MessageBuffer.flush() == []
    end

    test "returns messages in the order they were pushed" do
      MessageBuffer.push("First", :info)
      MessageBuffer.push([{"Second", :warning}, {"Third", :success}])
      MessageBuffer.push("Fourth", :info)

      assert MessageBuffer.flush() == [
               {"First", :info},
               {"Second", :warning},
               {"Third", :success},
               {"Fourth", :info}
             ]
    end
  end
end
