defmodule UndercityCli.SpinnerTest do
  use ExUnit.Case, async: false

  alias UndercityCli.Spinner

  setup do
    Spinner.start()
    on_exit(fn -> Spinner.stop() end)
    :ok
  end

  describe "start/1" do
    test "registers the process under its module name" do
      assert is_pid(Process.whereis(Spinner))
    end

    test "defaults message to nil (uses rotation)" do
      state = :sys.get_state(Spinner)
      assert is_nil(state.message)
    end

    test "accepts a custom initial message" do
      Spinner.stop()
      Spinner.start(message: "Connecting")
      state = :sys.get_state(Spinner)
      assert state.message == "Connecting"
    end
  end

  describe "update/1" do
    test "updates the displayed message" do
      Spinner.update("Almost there")
      state = :sys.get_state(Spinner)
      assert state.message == "Almost there"
    end
  end

  describe "stop/0" do
    test "stops the process" do
      Spinner.stop()
      refute Process.whereis(Spinner)
    end

    test "is safe to call when already stopped" do
      Spinner.stop()
      assert Spinner.stop() == :ok
    end
  end

  describe "success/1" do
    test "stops the process and returns :ok" do
      pid = Process.whereis(Spinner)
      ref = Process.monitor(pid)
      assert Spinner.success("Connected") == :ok
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  describe "failure/1" do
    test "stops the process and returns :ok" do
      pid = Process.whereis(Spinner)
      ref = Process.monitor(pid)
      assert Spinner.failure("Could not connect") == :ok
      assert_receive {:DOWN, ^ref, :process, ^pid, :normal}
    end
  end

  describe "handle_info :tick" do
    test "advances frame index" do
      %{frame_index: before_frame} = :sys.get_state(Spinner)
      send(Spinner, :tick)
      # Synchronise — :sys.get_state waits for the GenServer mailbox to drain
      %{frame_index: after_frame} = :sys.get_state(Spinner)
      assert after_frame != before_frame
    end

    test "advances text pulse index" do
      %{text_pulse_index: before_pulse} = :sys.get_state(Spinner)
      send(Spinner, :tick)
      %{text_pulse_index: after_pulse} = :sys.get_state(Spinner)
      assert after_pulse != before_pulse
    end
  end

  describe "handle_info :cycle_message" do
    test "advances message index" do
      %{message_index: before_index} = :sys.get_state(Spinner)
      send(Spinner, :cycle_message)
      %{message_index: after_index} = :sys.get_state(Spinner)
      assert after_index != before_index
    end

    test "wraps message index around at the end of the list" do
      # 19 messages defined in @messages, so last valid index is 18
      :sys.replace_state(Spinner, fn s -> %{s | message_index: 18} end)
      send(Spinner, :cycle_message)
      %{message_index: after_index} = :sys.get_state(Spinner)
      assert after_index == 0
    end
  end
end
