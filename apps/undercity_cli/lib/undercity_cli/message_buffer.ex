defmodule UndercityCli.MessageBuffer do
  @moduledoc """
  Agent-backed buffer for accumulating flash messages during a game session.

  - Stores `{text, category}` tuples pushed by command modules and the game loop
  - Flushed once per input cycle by `App` before the next render, appending to the message log
  - Registered under its own module name so any process can push messages without a PID reference
  - Categories are `:info`, `:success`, or `:warning`, which drive log colour in `View.Status`
  """

  @name __MODULE__

  @doc """
  Starts the MessageBuffer Agent, registering it under its module name.
  """
  def start_link(_opts \\ []) do
    Agent.start_link(fn -> [] end, name: @name)
  end

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent
    }
  end

  @doc """
  Pushes a single `{text, category}` message onto the buffer.
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
  Pushes an `:info` message onto the buffer.
  """
  def info(text), do: push(text, :info)

  @doc """
  Pushes a `:success` message onto the buffer.
  """
  def success(text), do: push(text, :success)

  @doc """
  Pushes a `:warning` message onto the buffer.
  """
  def warn(text), do: push(text, :warning)

  @doc """
  Returns all accumulated messages as a list and clears the buffer atomically.
  """
  def flush do
    Agent.get_and_update(@name, &{&1, []})
  end
end
