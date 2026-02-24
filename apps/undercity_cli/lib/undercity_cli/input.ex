defmodule UndercityCli.Input do
  @moduledoc """
  Reads a line of terminal input.

  Spawns a task for IO.gets so the process is never blocked permanently
  if the underlying IO stalls. Retries automatically on timeout, so gets/0
  always returns a normalised string.
  """

  @timeout 60_000

  def gets do
    caller = self()

    {:ok, task} =
      Task.start(fn ->
        input = IO.gets("")
        IO.write(["\r", IO.ANSI.cursor_up(1), "\e[0K"])
        send(caller, {:input, input})
      end)

    receive do
      {:input, input} -> input |> String.trim() |> String.downcase()
    after
      @timeout ->
        Task.shutdown(task, :kill)
        gets()
    end
  end
end
