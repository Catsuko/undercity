defmodule UndercityCli.Spinner do
  @moduledoc """
  An animated spinner for CLI feedback during connection.

  Uses braille dot patterns with color cycling for a smooth, modern feel.
  """

  use GenServer

  @frames ~w(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  @frame_rate 80

  @colors [:magenta, :light_magenta, :cyan, :light_cyan, :blue, :light_blue]

  @messages [
    "Establishing connection",
    "Descending into the undercity",
    "Tunneling through",
    "Searching for signal"
  ]

  # Client API

  @doc """
  Starts the spinner with the given options.

  ## Options
    * `:message` - Initial message to display (default: first from rotation)
  """
  def start(opts \\ []) do
    GenServer.start(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Updates the spinner message.
  """
  def update(message) do
    GenServer.cast(__MODULE__, {:update, message})
  end

  @doc """
  Stops the spinner with a success message.
  """
  def success(message) do
    GenServer.call(__MODULE__, {:stop, :success, message})
  end

  @doc """
  Stops the spinner with a failure message.
  """
  def failure(message) do
    GenServer.call(__MODULE__, {:stop, :failure, message})
  end

  @doc """
  Stops the spinner without a final message.
  """
  def stop do
    GenServer.call(__MODULE__, :stop)
  catch
    :exit, _ -> :ok
  end

  # Server Callbacks

  @impl true
  def init(opts) do
    state = %{
      frame_index: 0,
      color_index: 0,
      message_index: 0,
      message: opts[:message]
    }

    schedule_frame()
    render(state)

    {:ok, state}
  end

  @impl true
  def handle_cast({:update, message}, state) do
    {:noreply, %{state | message: message}}
  end

  @impl true
  def handle_call({:stop, status, message}, _from, state) do
    clear_line()
    render_final(status, message)
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    clear_line()
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    new_state = advance_state(state)
    render(new_state)
    schedule_frame()
    {:noreply, new_state}
  end

  # Private Functions

  defp schedule_frame do
    Process.send_after(self(), :tick, @frame_rate)
  end

  defp advance_state(state) do
    frame_index = rem(state.frame_index + 1, length(@frames))

    color_index =
      if frame_index == 0,
        do: rem(state.color_index + 1, length(@colors)),
        else: state.color_index

    message_index =
      if frame_index == 0 and color_index == 0,
        do: rem(state.message_index + 1, length(@messages)),
        else: state.message_index

    %{state | frame_index: frame_index, color_index: color_index, message_index: message_index}
  end

  defp render(state) do
    frame = Enum.at(@frames, state.frame_index)
    color = Enum.at(@colors, state.color_index)
    message = state.message || Enum.at(@messages, state.message_index)

    # Single write with cursor reset + content + clear to EOL to avoid flicker
    IO.write([
      "\r",
      " ",
      apply(IO.ANSI, color, []),
      frame,
      IO.ANSI.reset(),
      " ",
      message,
      "...",
      "\e[K"
    ])
  end

  defp render_final(:success, message) do
    IO.puts([
      " ",
      IO.ANSI.green(),
      "✓",
      IO.ANSI.reset(),
      " ",
      IO.ANSI.cyan(),
      message,
      IO.ANSI.reset()
    ])
  end

  defp render_final(:failure, message) do
    IO.puts([
      " ",
      IO.ANSI.red(),
      "✗",
      IO.ANSI.reset(),
      " ",
      IO.ANSI.magenta(),
      message,
      IO.ANSI.reset()
    ])
  end

  defp clear_line do
    IO.write(["\r", IO.ANSI.clear_line()])
  end
end
