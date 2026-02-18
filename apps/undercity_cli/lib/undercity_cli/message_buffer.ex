defmodule UndercityCli.MessageBuffer do
  @moduledoc """
  Agent-backed buffer for accumulating flash messages within a game session.

  Messages are pushed by commands and the game loop, then flushed once per
  input cycle before the next prompt is shown. The named Agent allows other
  processes (e.g. future pub/sub notifications) to push messages asynchronously.
  """

  @name __MODULE__

  @doc """
  Starts the MessageBuffer Agent, replacing any existing instance.
  """
  def start_link do
    if pid = Process.whereis(@name), do: Agent.stop(pid)
    Agent.start_link(fn -> [] end, name: @name)
  end

  @doc """
  Pushes a single message onto the buffer.
  """
  def push(text, category) when is_binary(text) do
    Agent.update(@name, &(&1 ++ [{text, category}]))
  end

  @doc """
  Pushes a list of `{text, category}` tuples onto the buffer.
  """
  def push(messages) when is_list(messages) do
    Agent.update(@name, &(&1 ++ messages))
  end

  @doc """
  Returns all accumulated messages and clears the buffer.
  """
  def flush do
    Agent.get_and_update(@name, &{&1, []})
  end
end
