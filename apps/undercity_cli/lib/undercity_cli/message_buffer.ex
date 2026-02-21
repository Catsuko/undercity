defmodule UndercityCli.MessageBuffer do
  @moduledoc """
  Agent-backed buffer for accumulating flash messages within a game session.

  Messages are pushed by commands and the game loop, then flushed once per
  input cycle before the next prompt is shown. The named Agent allows other
  processes (e.g. future pub/sub notifications) to push messages asynchronously.
  """

  @name __MODULE__

  @doc """
  Starts the MessageBuffer Agent under a supervisor.
  """
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> [] end, name: @name)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
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

  @doc "Pushes an info message onto the buffer."
  def info(text), do: push(text, :info)

  @doc "Pushes a success message onto the buffer."
  def success(text), do: push(text, :success)

  @doc "Pushes a warning message onto the buffer."
  def warn(text), do: push(text, :warning)

  @doc """
  Returns all accumulated messages and clears the buffer.
  """
  def flush do
    Agent.get_and_update(@name, &{&1, []})
  end
end
